# frozen_string_literal: true

module ContributesToPatientTeams
  extend ActiveSupport::Concern

  module Relation
    def contributing_subqueries
      case table_name
      when "patient_locations"
        {
          patient_location: {
            patient_id_source: "patient_locations.patient_id",
            team_id_source: "team_locations.team_id",
            contribution_scope: joins_team_locations
          }
        }
      when "archive_reasons"
        {
          archive_reason: {
            patient_id_source: "archive_reasons.patient_id",
            team_id_source: "archive_reasons.team_id",
            contribution_scope: all
          }
        }
      when "vaccination_records"
        {
          vaccination_record_session: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "team_locations.team_id",
            contribution_scope: joins(session: :team_location)
          },
          vaccination_record_organisation: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "teams.id",
            contribution_scope:
              joins_teams_on_performed_ods_code.where(session_id: nil)
          },
          vaccination_record_import: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "immunisation_imports.team_id",
            contribution_scope: joins(:immunisation_imports)
          }
        }
      when "school_moves"
        {
          school_move_team: {
            patient_id_source: "school_moves.patient_id",
            team_id_source: "school_moves.team_id",
            contribution_scope: where("school_moves.team_id IS NOT NULL")
          },
          school_move_school: {
            patient_id_source: "school_moves.patient_id",
            team_id_source: "tl.team_id",
            contribution_scope:
              joins(join_team_locations_to_school_moves).where("loc.type = 0")
          }
        }
      when "sessions"
        {
          vaccination_record_session: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "team_locations.team_id",
            contribution_scope:
              joins(:team_location).joins(:vaccination_records)
          }
        }
      when "organisations"
        {
          vaccination_record_organisation: {
            patient_id_source: "vacs.patient_id",
            team_id_source: "teams.id",
            contribution_scope:
              joins(join_vaccination_records_to_organisation).joins(
                :teams
              ).where("vacs.session_id IS NULL")
          }
        }
      when "teams"
        {
          school_move_school: {
            patient_id_source: "schlm.patient_id",
            team_id_source: "team_locations.team_id",
            contribution_scope:
              joins(:schools).joins(join_school_moves_to_team_locations)
          },
          vaccination_record_organisation: {
            patient_id_source: "vacs.patient_id",
            team_id_source: "teams.id",
            contribution_scope:
              joins(:organisation).joins(
                join_vaccination_records_to_organisation
              ).where("vacs.session_id IS NULL")
          }
        }
      when "team_locations"
        {
          school_move_school: {
            patient_id_source: "schlm.patient_id",
            team_id_source: "team_locations.team_id",
            contribution_scope:
              joins(:location).merge(Location.school).joins(
                join_school_moves_to_team_locations
              )
          }
        }
      else
        raise "Unknown table for PatientTeamContributor"
      end
    end

    def insert_patient_teams_relationships
      transaction { add_patient_team_relationships }
    end

    def add_patient_team_relationships(patient_ids: nil)
      contributing_subqueries.each do |key, subquery|
        source_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
        patient_id_source =
          connection.quote_string(subquery[:patient_id_source])
        team_id_source = connection.quote_string(subquery[:team_id_source])
        contribution_scope = subquery[:contribution_scope]
        if patient_ids.present?
          contribution_scope =
            contribution_scope.where(
              "#{patient_id_source} = ANY(ARRAY[?]::bigint[])",
              patient_ids
            )
        end

        insert_from =
          contribution_scope
            .select(
              "#{patient_id_source} as patient_id",
              "#{team_id_source} as team_id"
            )
            .distinct
            .to_sql
        connection.execute <<-SQL
          INSERT INTO patient_teams (patient_id, team_id, sources)
          SELECT alias.patient_id, alias.team_id, ARRAY[#{source_key}]
            FROM (#{insert_from}) as alias
          ON CONFLICT (team_id, patient_id) DO UPDATE
            SET sources = array_append(array_remove(patient_teams.sources,#{source_key}),#{source_key})
        SQL
      end
    end

    private

    def join_vaccination_records_to_organisation
      <<-SQL
      INNER JOIN vaccination_records vacs
        ON vacs.performed_ods_code = organisations.ods_code
      SQL
    end

    def join_team_locations_to_school_moves
      <<-SQL
      INNER JOIN locations loc
        ON school_moves.school_id = loc.id
      INNER JOIN team_locations tl
        ON loc.id = tl.location_id
        AND school_moves.academic_year = tl.academic_year
      SQL
    end

    def join_school_moves_to_team_locations
      <<-SQL
      INNER JOIN school_moves schlm
        ON schlm.school_id = team_locations.team_id
        AND schlm.academic_year = team_locations.academic_year
      SQL
    end
  end

  included do
    after_create :after_create_add_source_to_patient_teams
    around_update :around_update_sync_source_of_patient_teams
    around_destroy :around_destroy_remove_source_from_patient_teams
  end

  private

  def after_create_add_source_to_patient_teams
    fetch_source_and_patient_team_ids.each do |source, patient_team_ids|
      patient_team_ids.each do |patient_id, team_id|
        PatientTeam.find_or_initialize_by(patient_id:, team_id:).add_source!(
          source
        )
      end
    end
  end

  def around_update_sync_source_of_patient_teams
    old_patient_team_ids = fetch_source_and_patient_team_ids

    yield

    new_patient_team_ids = fetch_source_and_patient_team_ids

    kept_patient_team_ids =
      fetch_source_and_still_existing_patient_team_ids(old_patient_team_ids)

    removed_patient_team_ids =
      old_patient_team_ids
        .map { |key, value| [key, (value - kept_patient_team_ids[key])] }
        .to_h

    inserted_patient_team_ids =
      new_patient_team_ids
        .map { |key, value| [key, (value - kept_patient_team_ids[key])] }
        .to_h

    removed_patient_team_ids.each do |source, patient_team_ids|
      patient_team_ids.each do |patient_id, team_id|
        PatientTeam.find_by(patient_id:, team_id:)&.remove_source!(source)
      end
    end

    inserted_patient_team_ids.each do |source, patient_team_ids|
      patient_team_ids.each do |patient_id, team_id|
        PatientTeam.find_or_initialize_by(patient_id:, team_id:).add_source!(
          source
        )
      end
    end
  end

  def around_destroy_remove_source_from_patient_teams
    affected_patient_team_ids = fetch_source_and_patient_team_ids

    yield

    kept_patient_team_ids =
      fetch_source_and_still_existing_patient_team_ids(
        affected_patient_team_ids
      )

    removed_patient_team_ids =
      affected_patient_team_ids
        .map { |key, value| [key, (value - kept_patient_team_ids[key])] }
        .to_h

    removed_patient_team_ids.each do |source, patient_team_ids|
      patient_team_ids.each do |patient_id, team_id|
        PatientTeam.find_by(patient_id:, team_id:)&.remove_source!(source)
      end
    end
  end

  def fetch_source_and_patient_team_ids
    self
      .class
      .where(id:)
      .contributing_subqueries
      .transform_values do |subquery|
        subquery
          .fetch(:contribution_scope)
          .distinct
          .pluck(
            subquery.fetch(:patient_id_source),
            subquery.fetch(:team_id_source)
          )
      end
  end

  def fetch_source_and_still_existing_patient_team_ids(
    patient_team_ids_by_source
  )
    # This method find patient teams that still need to exist even if another
    # contributing row has been updated or deleted. This works by searching
    # for all the rows and then filtering on patient IDs and team IDs.

    self
      .class
      .all
      .contributing_subqueries
      .each_with_object({}) do |(source, subquery), hash|
        patient_team_ids = patient_team_ids_by_source.fetch(source)

        hash[source] = if patient_team_ids.present?
          patient_id_source = subquery.fetch(:patient_id_source)
          team_id_source = subquery.fetch(:team_id_source)

          in_query_string = patient_team_ids.map { "(#{_1},#{_2})" }.join(",")

          where_clause =
            ActiveRecord::Base.connection.quote_string(
              "(#{patient_id_source}, #{team_id_source}) " \
                " IN (#{in_query_string})"
            )

          subquery
            .fetch(:contribution_scope)
            .where(where_clause)
            .distinct
            .pluck(patient_id_source, team_id_source)
        else
          []
        end
      end
  end
end
