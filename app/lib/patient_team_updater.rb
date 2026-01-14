# frozen_string_literal: true

class PatientTeamUpdater
  def initialize(patient_scope: nil, team_scope: nil)
    @patient_scope = patient_scope
    @team_scope = team_scope
  end

  def call
    upsert_patient_teams!
    delete_patient_teams_without_sources!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_scope, :team_scope

  def upsert_patient_teams!
    patient_team_rows.in_groups_of(10_000, false) do |rows|
      PatientTeam.import!(
        %i[patient_id team_id sources],
        rows,
        on_duplicate_key_update: {
          conflict_target: %i[patient_id team_id],
          columns: %i[sources]
        }
      )
    end
  end

  def delete_patient_teams_without_sources!
    PatientTeam.missing_sources.delete_all
  end

  def patient_team_rows
    @patient_team_rows ||=
      patient_team_sources.map do |(patient_id, team_id), sources|
        [patient_id, team_id, sources]
      end
  end

  def patient_team_sources
    @patient_team_sources ||=
      sources.each_with_object(
        existing_patient_team_pairs
      ) do |(source, patient_team_pairs), hash|
        patient_team_pairs.each do |patient_team_pair|
          hash[patient_team_pair] ||= []
          hash[patient_team_pair] << PatientTeam.sources.fetch(source)
        end
      end
  end

  def existing_patient_team_pairs
    scope = merge_team_scope(merge_patient_scope(PatientTeam))

    scope.pluck(:patient_id, :team_id).index_with { |_pair| [] }
  end

  def sources
    @sources ||= {
      archive_reason: archive_reasons,
      patient_location: patient_locations,
      school_move_school: school_moves_by_school,
      school_move_team: school_moves_by_team,
      vaccination_record_import: vaccination_records_by_import,
      vaccination_record_organisation: vaccination_records_by_organisation,
      vaccination_record_session: vaccination_records_by_session
    }
  end

  def archive_reasons
    scope = merge_team_scope(merge_patient_scope(ArchiveReason))

    scope.pluck(:patient_id, :team_id)
  end

  def patient_locations
    # We define an alias here in case the `patient_scope` already includes a
    #  join on the `team_locations` table.

    scope =
      merge_patient_scope(
        joins_team_locations_alias_on_patient_locations(PatientLocation)
      )

    if is_team_scope_id_only?
      scope =
        scope.where(team_locations_alias: { team_id: team_scope.select(:id) })
    elsif team_scope
      scope = joins_teams_on_team_locations_alias(scope).merge(team_scope)
    end

    scope.pluck(:patient_id, :"team_locations_alias.team_id")
  end

  def school_moves_by_school
    # We define an alias here in case the `patient_scope` already includes a
    #  join on the `team_locations` table.

    scope =
      merge_patient_scope(
        joins_team_locations_alias_on_school_moves(SchoolMove)
      )

    if is_team_scope_id_only?
      scope =
        scope.where(team_locations_alias: { team_id: team_scope.select(:id) })
    elsif team_scope
      scope = joins_teams_on_team_locations_alias(scope).merge(team_scope)
    end

    scope.pluck(:patient_id, :"team_locations_alias.team_id")
  end

  def school_moves_by_team
    scope =
      merge_team_scope(merge_patient_scope(SchoolMove.where.not(team_id: nil)))

    scope.pluck(:patient_id, :team_id)
  end

  def vaccination_records_by_import
    scope = merge_patient_scope(VaccinationRecord.joins(:immunisation_imports))

    if is_team_scope_id_only?
      scope =
        scope.where(immunisation_imports: { team_id: team_scope.select(:id) })
    elsif team_scope
      scope = scope.joins(immunisation_imports: :team).merge(team_scope)
    end

    scope.pluck(:patient_id, :"immunisation_imports.team_id")
  end

  def vaccination_records_by_organisation
    scope =
      merge_patient_scope(
        VaccinationRecord.where(
          session_id: nil
        ).joins_teams_on_performed_ods_code
      )

    scope = scope.merge(team_scope) if team_scope

    scope.pluck(:patient_id, :"teams.id")
  end

  def vaccination_records_by_session
    # We define an alias here in case the `patient_scope` already includes a
    #  join on the `sessions` table or `team_locations` table.

    scope =
      merge_patient_scope(
        joins_team_locations_alias_on_vaccination_records(VaccinationRecord)
      )

    if is_team_scope_id_only?
      scope =
        scope.where(team_locations_alias: { team_id: team_scope.select(:id) })
    elsif team_scope
      scope = joins_teams_on_team_locations_alias(scope).merge(team_scope)
    end

    scope.pluck(:patient_id, :"team_locations_alias.team_id")
  end

  # These are aliased joins that we need to perform in case the patient or
  #  team scopes already make reference to these tables.

  def joins_team_locations_alias_on_patient_locations(scope)
    scope.joins(<<-SQL).references(:team_locations_alias)
      INNER JOIN team_locations team_locations_alias
      ON team_locations_alias.location_id = patient_locations.location_id
      AND team_locations_alias.academic_year = patient_locations.academic_year
    SQL
  end

  def joins_team_locations_alias_on_school_moves(scope)
    scope.joins(<<-SQL).references(:team_locations_alias)
      INNER JOIN team_locations team_locations_alias
      ON team_locations_alias.location_id = school_moves.school_id
      AND team_locations_alias.academic_year = school_moves.academic_year
    SQL
  end

  def joins_team_locations_alias_on_vaccination_records(scope)
    scope.joins(<<-SQL).references(:sessions_alias, :team_locations_alias)
      INNER JOIN sessions sessions_alias
      ON sessions_alias.id = vaccination_records.session_id
      INNER JOIN team_locations team_locations_alias
      ON team_locations_alias.id = sessions_alias.team_location_id
    SQL
  end

  def joins_teams_on_team_locations_alias(scope)
    scope.joins("INNER JOIN teams ON teams.id = team_locations_alias.team_id")
  end

  # The following code is necessary to support an optimisation where we're
  #  updating a specific team or patient by ID.
  #
  # These methods allow us to check if the scope where clause is only checking
  #  the ID of the patient or team, meaning we can optimise out the `JOIN` and
  #  filter the table directly.
  #
  # For example, without this optimisation, a scope of `Patient.where(id: 1)`
  #  would result in the following SQL query:
  #
  # SELECT patient_id, team_id FROM patient_teams
  # JOIN patients ON patients.id = patient_teams.patient_id
  # WHERE patients.id = 1
  #
  # Whereas we know that the following SQL query is all we need in this case:
  #
  # SELECT patient_id, team_id FROM patient_teams
  # WHERE patient_teams.patient_id = 1

  def merge_patient_scope(scope)
    if is_patient_scope_id_only?
      scope.where(patient_id: patient_scope.select(:id))
    elsif patient_scope
      scope.joins(:patient).merge(patient_scope)
    else
      scope
    end
  end

  def merge_team_scope(scope)
    if is_team_scope_id_only?
      scope.where(team_id: team_scope.select(:id))
    elsif team_scope
      scope.joins(:team).merge(team_scope)
    else
      scope
    end
  end

  def is_patient_scope_id_only?
    @is_patient_scope_id_only ||= is_id_only_scope?(patient_scope)
  end

  def is_team_scope_id_only?
    @is_team_scope_id_only ||= is_id_only_scope?(team_scope)
  end

  def is_id_only_scope?(scope)
    if scope.nil? || scope.joins_values.any? ||
         scope.left_outer_joins_values.any?
      return false
    end

    values = scope.where_values_hash
    values.key?("id") && values.size == 1
  end
end
