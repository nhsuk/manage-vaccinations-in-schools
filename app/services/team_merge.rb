# frozen_string_literal: true

class TeamMerge
  Error = Class.new(StandardError)

  SIMPLE_MODELS = [
    ClassImport,
    ClinicNotification,
    CohortImport,
    Consent,
    ImmunisationImport,
    PatientSpecificDirection,
    SchoolMoveLogEntry,
    SchoolMove,
    Triage
  ].freeze

  attr_reader :source_teams, :new_team_attrs, :errors, :dry_run_report

  def initialize(source_teams:, new_team_attrs:)
    @source_teams = source_teams
    @new_team_attrs = new_team_attrs
    @errors = []
    @dry_run_report = []
  end

  def valid?
    @errors = []
    validate_minimum_teams
    validate_same_organisation
    validate_same_type
    detect_archive_reason_conflicts
    detect_subteam_conflicts
    detect_team_location_conflicts
    @errors.empty?
  end

  def dry_run
    valid? # populate errors
    @dry_run_report = []
    append_migration_counts
    append_batch_skips
    append_archive_reason_merges

    if @errors.empty?
      @dry_run_report << "Merge would succeed."
    else
      @dry_run_report << "Merge would ABORT with #{@errors.size} error(s):"
      @errors.each { |e| @dry_run_report << "  ERROR: #{e}" }
    end

    @dry_run_report
  end

  def call!
    raise Error, @errors.join("; ") unless valid?

    result =
      ActiveRecord::Base.transaction do
        merged_team = Team.create!(new_team_attrs)
        migrate_simple_tables(merged_team)
        migrate_batches(merged_team)
        migrate_archive_reasons(merged_team)
        migrate_important_notices(merged_team)
        migrate_subteams(merged_team)
        migrate_generic_clinics(merged_team)
        migrate_team_locations(merged_team)
        migrate_teams_users(merged_team)
        PatientTeamUpdater.call(
          team_scope:
            Team.where(id: source_teams.map(&:id)).or(
              Team.where(id: merged_team.id)
            )
        )
        source_teams.each(&:destroy!)
        merged_team
      end

    refresh_materialized_views
    result
  end

  private

  def validate_minimum_teams
    if source_teams.size < 2
      @errors << "At least two source teams are required."
    end
  end

  def validate_same_organisation
    return if source_teams.map(&:organisation_id).uniq.size == 1

    @errors << "Teams belong to different organisations: " \
      "#{source_teams.map { |t| "#{t.workgroup}(org #{t.organisation_id})" }.join(", ")}"
  end

  def validate_same_type
    return if source_teams.map(&:type).uniq.size == 1

    @errors << "Teams have different types: " \
      "#{source_teams.map { |t| "#{t.workgroup}(#{t.type})" }.join(", ")}"
  end

  def source_team_ids
    @source_team_ids ||= source_teams.map(&:id)
  end

  def source_teams_by_id
    @source_teams_by_id ||= source_teams.index_by(&:id)
  end

  # --- Conflict detection ---

  def active_in_some_source_team_ids
    @active_in_some_source_team_ids ||=
      PatientTeam
        .where(team_id: source_team_ids)
        .joins(
          "LEFT JOIN archive_reasons ar ON ar.patient_id = patient_teams.patient_id
                                            AND ar.team_id    = patient_teams.team_id"
        )
        .where("ar.id IS NULL")
        .distinct
        .pluck(:patient_id)
  end

  def detect_archive_reason_conflicts
    patient_ids_with_reasons =
      ArchiveReason.where(team_id: source_team_ids).distinct.pluck(:patient_id)

    fully_archived_ids =
      patient_ids_with_reasons - active_in_some_source_team_ids

    return if fully_archived_ids.empty?

    types_by_patient = Hash.new { |h, k| h[k] = [] }
    ArchiveReason
      .where(team_id: source_team_ids, patient_id: fully_archived_ids)
      .pluck(:patient_id, :type)
      .each { |pid, type| types_by_patient[pid] << type }

    types_by_patient.each do |patient_id, types|
      next if types.uniq.size <= 1
      @errors << "Patient #{patient_id} has archive reasons with different types " \
        "(#{types.uniq.join(", ")}) across source teams"
    end
  end

  def detect_subteam_conflicts
    all_names = source_teams.flat_map { |t| t.subteams.pluck(:name) }
    all_names
      .tally
      .select { |_name, count| count > 1 }
      .each_key do |name|
        @errors << "Subteam '#{name}' exists in multiple source teams"
      end
  end

  def detect_team_location_conflicts
    TeamLocation
      .where(team_id: source_team_ids)
      .group(:academic_year, :location_id)
      .having(Arel.sql("COUNT(*) > 1"))
      .pluck(
        :location_id,
        :academic_year,
        Arel.sql("COUNT(DISTINCT COALESCE(subteam_id::text, 'NULL'))")
      )
      .each do |location_id, academic_year, subteam_variants|
        if subteam_variants > 1
          @errors << "Location #{location_id} (year #{academic_year}) " \
            "is assigned to different subteams across source teams"
        end
      end
  end

  # --- Migration ---

  def migrate_simple_tables(merged_team)
    SIMPLE_MODELS.each do |model|
      model.where(team_id: source_team_ids).update_all(team_id: merged_team.id)
    end
  end

  def migrate_batches(merged_team)
    keep_ids =
      Batch
        .where(team_id: source_team_ids)
        .group(:number, :expiry, :vaccine_id)
        .minimum(:id)
        .values
    Batch.where(team_id: source_team_ids).where.not(id: keep_ids).delete_all
    Batch.where(team_id: source_team_ids).update_all(team_id: merged_team.id)
  end

  def migrate_archive_reasons(merged_team)
    patient_ids_with_reasons =
      ArchiveReason.where(team_id: source_team_ids).distinct.pluck(:patient_id)

    fully_archived = patient_ids_with_reasons - active_in_some_source_team_ids
    @patients_to_unarchive = patient_ids_with_reasons - fully_archived

    # Remove archive reasons for partially-archived patients
    ArchiveReason.where(
      team_id: source_team_ids,
      patient_id: @patients_to_unarchive
    ).delete_all

    # Migrate archive reasons for fully-archived patients
    fully_archived.each do |patient_id|
      records =
        ArchiveReason
          .where(team_id: source_team_ids, patient_id:)
          .order(:id)
          .to_a
      surviving = records.first

      if records.size > 1 && surviving.other?
        merged_details =
          records
            .map do |ar|
              "#{source_teams_by_id[ar.team_id].name}: #{ar.other_details}"
            end
            .join("\n\n")
        surviving.update_column(:other_details, merged_details)
      end

      ArchiveReason.where(id: records[1..].map(&:id)).delete_all
      surviving.update_column(:team_id, merged_team.id)
    end
  end

  def migrate_important_notices(merged_team)
    keep_ids =
      ImportantNotice
        .where(team_id: source_team_ids)
        .group(:patient_id, :type, :recorded_at)
        .minimum(:id)
        .values
    ImportantNotice
      .where(team_id: source_team_ids)
      .where.not(id: keep_ids)
      .delete_all
    ImportantNotice.where(team_id: source_team_ids).update_all(
      team_id: merged_team.id
    )
  end

  def migrate_subteams(merged_team)
    Subteam.where(team_id: source_team_ids).update_all(team_id: merged_team.id)
  end

  def migrate_teams_users(merged_team)
    # teams_users is a HABTM join table with no AR model; raw SQL is the appropriate tool here
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO teams_users (team_id, user_id)
      SELECT DISTINCT #{merged_team.id}, user_id
      FROM teams_users
      WHERE team_id IN (#{source_team_ids.join(",")})
      ON CONFLICT DO NOTHING
    SQL
  end

  def migrate_team_locations(merged_team)
    source_teams.each do |source_team|
      source_team.team_locations.find_each do |tl|
        if TeamLocation.exists?(
             team_id: merged_team.id,
             academic_year: tl.academic_year,
             location_id: tl.location_id
           )
          tl.destroy!
        else
          tl.update_columns(team_id: merged_team.id)
        end
      end
    end
  end

  def migrate_generic_clinics(merged_team)
    source_gc_tl_ids =
      TeamLocation
        .joins(:location)
        .where(team_id: source_team_ids)
        .merge(Location.generic_clinic)
        .pluck(:id)

    source_gc_tls = TeamLocation.where(id: source_gc_tl_ids)
    academic_years = source_gc_tls.distinct.pluck(:academic_year)
    source_gc_location_ids = source_gc_tls.distinct.pluck(:location_id)

    academic_years.each do |year|
      GenericClinicFactory.call(team: merged_team.reload, academic_year: year)
    end
    merged_gc = merged_team.generic_clinic

    source_gc_tls.find_each do |old_tl|
      merged_tl =
        TeamLocation.find_by!(
          team: merged_team,
          location: merged_gc,
          academic_year: old_tl.academic_year
        )
      Session.where(team_location_id: old_tl.id).update_all(
        team_location_id: merged_tl.id
      )
      ConsentForm.where(team_location_id: old_tl.id).update_all(
        team_location_id: merged_tl.id
      )
    end

    VaccinationRecord.where(location_id: source_gc_location_ids).update_all(
      location_id: merged_gc.id
    )

    keep_ids =
      PatientLocation
        .where(location_id: source_gc_location_ids)
        .group(:patient_id, :academic_year)
        .minimum(:id)
        .values
    PatientLocation
      .where(location_id: source_gc_location_ids)
      .where.not(id: keep_ids)
      .delete_all
    PatientLocation.where(id: keep_ids).update_all(location_id: merged_gc.id)

    [AttendanceRecord, GillickAssessment, PreScreening].each do |model|
      model.where(location_id: source_gc_location_ids).update_all(
        location_id: merged_gc.id
      )
    end
    ConsentForm.where(school_id: source_gc_location_ids).update_all(
      school_id: merged_gc.id
    )

    source_gc_tls.delete_all
    Location::ProgrammeYearGroup
      .joins(:location_year_group)
      .where(location_year_groups: { location_id: source_gc_location_ids })
      .delete_all
    Location::YearGroup.where(location_id: source_gc_location_ids).delete_all
    Location.where(id: source_gc_location_ids).delete_all
  end

  def refresh_materialized_views
    ReportingAPI::Total.refresh!(concurrently: false)
    ReportingAPI::PatientProgrammeStatus.refresh!(concurrently: false)
  rescue => e
    Rails.logger.warn "TeamMerge: could not refresh materialized views: #{e.message}"
  end

  def append_migration_counts
    SIMPLE_MODELS.each do |model|
      count = model.where(team_id: source_team_ids).count
      if count > 0
        @dry_run_report << "#{model.table_name}: #{count} row(s) to migrate"
      end
    end

    {
      "archive_reasons" => ArchiveReason.where(team_id: source_team_ids).count,
      "important_notices" =>
        ImportantNotice.where(team_id: source_team_ids).count,
      "subteams" => Subteam.where(team_id: source_team_ids).count,
      "batches" => Batch.where(team_id: source_team_ids).count,
      "patients" =>
        PatientTeam
          .where(team_id: source_team_ids)
          .select(:patient_id)
          .distinct
          .count,
      "team_locations" => TeamLocation.where(team_id: source_team_ids).count,
      "teams_users" =>
        User.joins(:teams).where(teams: { id: source_team_ids }).distinct.count
    }.each do |table, count|
      @dry_run_report << "#{table}: #{count} row(s) to migrate" if count > 0
    end
  end

  def append_archive_reason_merges
    all_ids =
      ArchiveReason.where(team_id: source_team_ids).distinct.pluck(:patient_id)
    active_ids = active_in_some_source_team_ids.to_set
    partial = all_ids.select { |pid| active_ids.include?(pid) }
    fully = all_ids - partial

    if partial.any?
      @dry_run_report << "#{partial.size} patient(s) will be unarchived " \
        "(active in at least one source team)"
    end

    fully.each do |patient_id|
      records = ArchiveReason.where(team_id: source_team_ids, patient_id:).to_a
      if records.size > 1 && records.first.other?
        details =
          records
            .map do |ar|
              "#{source_teams_by_id[ar.team_id].name}: #{ar.other_details}"
            end
            .join(", ")
        @dry_run_report << "Patient #{patient_id}: merging other_details → #{details}"
      end
    end
  end

  def append_batch_skips
    Batch
      .where(team_id: source_team_ids)
      .group(:number, :expiry, :vaccine_id)
      .having(Arel.sql("COUNT(DISTINCT team_id) > 1"))
      .pluck(:number, :expiry, :vaccine_id)
      .each do |number, expiry, vaccine_id|
        @dry_run_report << "Batch #{number}/vaccine #{vaccine_id}/expiry #{expiry}: " \
          "duplicate across teams, will be skipped"
      end
  end
end
