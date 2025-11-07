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
            team_id_source: "sessions.team_id",
            contribution_scope: joins_sessions
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
            team_id_source: "sessions.team_id",
            contribution_scope: joins(:session)
          },
          vaccination_record_organisation: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "tms.id",
            contribution_scope:
              joins(join_teams_to_vaccinations_via_organisation).where(
                session_id: nil
              )
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
            team_id_source: "stm.team_id",
            contribution_scope:
              joins(join_subteams_to_school_moves_via_location).where(
                "loc.type = 0"
              )
          }
        }
      when "sessions"
        {
          patient_location: {
            patient_id_source: "patient_locations.patient_id",
            team_id_source: "sessions.team_id",
            contribution_scope: joins_patient_locations
          },
          vaccination_record_session: {
            patient_id_source: "vaccination_records.patient_id",
            team_id_source: "sessions.team_id",
            contribution_scope: joins(:vaccination_records)
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
          vaccination_record_organisation: {
            patient_id_source: "vacs.patient_id",
            team_id_source: "teams.id",
            contribution_scope:
              joins(:organisation).joins(
                join_vaccination_records_to_organisation
              ).where("vacs.session_id IS NULL")
          }
        }
      when "locations"
        {
          school_move_school: {
            patient_id_source: "schlm.patient_id",
            team_id_source: "subteams.team_id",
            contribution_scope:
              joins(:subteam).joins(join_school_moves_to_location).where(
                type: 0
              )
          }
        }
      when "subteams"
        {
          school_move_school: {
            patient_id_source: "schlm.patient_id",
            team_id_source: "subteams.id",
            contribution_scope:
              joins(:schools).joins(join_school_moves_to_location)
          }
        }
      else
        raise "Unknown table for PatientTeamContributor"
      end
    end

    def update_all_and_sync_patient_teams(updates)
      transaction do
        contributing_subqueries.each do |key, subquery|
          affected_row_ids = connection.quote_table_name("temp_table_#{key}")
          sterile_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
          patient_id_source =
            connection.quote_string(subquery[:patient_id_source])
          team_id_source = connection.quote_string(subquery[:team_id_source])

          source_table_affected_rows =
            all.select("#{table_name}.id as id").to_sql
          connection.execute <<-SQL
          CREATE TEMPORARY TABLE #{affected_row_ids} (
            id bigint
          ) ON COMMIT DROP;
          INSERT INTO #{affected_row_ids} (id) #{source_table_affected_rows};
          SQL

          patient_team_relationships_to_remove =
            subquery[:contribution_scope]
              .select(
                "#{patient_id_source} as patient_id",
                "#{team_id_source} as team_id"
              )
              .reorder("patient_id")
              .distinct
              .to_sql
          connection.execute <<-SQL
          UPDATE patient_teams pt
            SET sources = array_remove(sources, #{sterile_key})
          FROM (#{patient_team_relationships_to_remove}) as pre_changed
            WHERE pt.patient_id = pre_changed.patient_id AND pt.team_id = pre_changed.team_id;
          SQL
        end

        update_all(updates)

        klass.all.contributing_subqueries.each do |key, subquery|
          modified_row_ids = connection.quote_table_name("temp_table_#{key}")
          sterile_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
          patient_id_source =
            connection.quote_string(subquery[:patient_id_source])
          team_id_source = connection.quote_string(subquery[:team_id_source])

          patient_team_relationships_to_insert =
            subquery[:contribution_scope]
              .select(
                "#{patient_id_source} as patient_id",
                "#{team_id_source} as team_id"
              )
              .joins(
                "INNER JOIN #{modified_row_ids} ON #{modified_row_ids}.id = #{table_name}.id"
              )
              .reorder("patient_id")
              .distinct
              .to_sql

          connection.execute <<-SQL
          INSERT INTO patient_teams (patient_id, team_id, sources)
            SELECT post_changed.patient_id, post_changed.team_id, ARRAY[#{sterile_key}]
          FROM (#{patient_team_relationships_to_insert}) as post_changed
            ON CONFLICT (team_id, patient_id) DO UPDATE
            SET sources = array_append(array_remove(patient_teams.sources,#{sterile_key}),#{sterile_key})
          SQL

          connection.execute("DROP TABLE IF EXISTS #{modified_row_ids}")

          PatientTeam.missing_sources.delete_all
        end
      end
    end

    def delete_all_and_sync_patient_teams
      transaction do
        contributing_subqueries.each do |key, subquery|
          patient_id_source =
            connection.quote_string(subquery[:patient_id_source])
          team_id_source = connection.quote_string(subquery[:team_id_source])
          sterile_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
          delete_from =
            subquery[:contribution_scope]
              .select(
                "#{patient_id_source} as patient_id",
                "#{team_id_source} as team_id"
              )
              .reorder("patient_id")
              .distinct
              .to_sql

          connection.execute <<-SQL
          UPDATE patient_teams pt
            SET sources = array_remove(pt.sources, #{sterile_key})
          FROM (#{delete_from}) AS del
            WHERE pt.patient_id = del.patient_id AND pt.team_id = del.team_id;
          SQL

          PatientTeam.missing_sources.delete_all
        end

        delete_all
      end
    end

    def insert_patient_teams_relationships
      transaction { add_patient_team_relationships }
    end

    def sync_patient_teams_table_on_patient_ids(pk_ids)
      transaction do
        contributing_subqueries.each do |key, subquery|
          patient_id_source =
            connection.quote_string(subquery[:patient_id_source])
          sterile_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
          patient_relationships_to_remove =
            select("#{patient_id_source} as patient_id")
              .where("#{table_name}.id = ANY(ARRAY[?]::bigint[])", pk_ids)
              .distinct
              .to_sql
          connection.execute <<-SQL
          UPDATE patient_teams pt
            SET sources = array_remove(sources, #{sterile_key})
          FROM (#{patient_relationships_to_remove}) as alias
            WHERE pt.patient_id = alias.patient_id;
          SQL
        end

        where(
          "#{table_name}.id = ANY(ARRAY[?]::bigint[])",
          pk_ids
        ).distinct.add_patient_team_relationships

        PatientTeam.missing_sources.delete_all
      end
    end

    def add_patient_team_relationships
      contributing_subqueries.each do |key, subquery|
        sterile_key = connection.quote(PatientTeam.sources.fetch(key.to_s))
        patient_id_source =
          connection.quote_string(subquery[:patient_id_source])
        team_id_source = connection.quote_string(subquery[:team_id_source])
        insert_from =
          subquery[:contribution_scope]
            .select(
              "#{patient_id_source} as patient_id",
              "#{team_id_source} as team_id"
            )
            .distinct
            .to_sql
        connection.execute <<-SQL
          INSERT INTO patient_teams (patient_id, team_id, sources)
          SELECT alias.patient_id, alias.team_id, ARRAY[#{sterile_key}]
            FROM (#{insert_from}) as alias
          ON CONFLICT (team_id, patient_id) DO UPDATE
            SET sources = array_append(array_remove(patient_teams.sources,#{sterile_key}),#{sterile_key})
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

    def join_teams_to_vaccinations_via_organisation
      <<-SQL
      INNER JOIN organisations org
          ON vaccination_records.performed_ods_code = org.ods_code
      INNER JOIN teams tms
          ON org.id = tms.organisation_id
      SQL
    end

    def join_subteams_to_school_moves_via_location
      <<-SQL
      INNER JOIN locations loc
        ON school_moves.school_id = loc.id
      INNER JOIN subteams stm
        ON loc.subteam_id = stm.id
      SQL
    end

    def join_school_moves_to_location
      <<-SQL
      INNER JOIN school_moves schlm
        ON schlm.school_id = locations.id
      SQL
    end
  end

  included do
    after_create :after_create_add_source_to_patient_teams
    around_update :after_update_sync_source_of_patient_teams
    before_destroy :before_destroy_remove_source_from_patient_teams
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

  def after_update_sync_source_of_patient_teams
    subquery_identifiers = self.class.all.contributing_subqueries.keys

    old_patient_team_ids = fetch_source_and_patient_team_ids
    yield
    new_patient_team_ids = fetch_source_and_patient_team_ids

    unmodified_patient_team_ids =
      subquery_identifiers.index_with do |key|
        old_patient_team_ids[key] & new_patient_team_ids[key]
      end

    removed_patient_team_ids =
      old_patient_team_ids
        .map { |key, value| [key, (value - unmodified_patient_team_ids[key])] }
        .to_h
    inserted_patient_team_ids =
      new_patient_team_ids
        .map { |key, value| [key, (value - unmodified_patient_team_ids[key])] }
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

  def before_destroy_remove_source_from_patient_teams
    fetch_source_and_patient_team_ids.each do |source, patient_team_ids|
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
          .select(
            "#{subquery.fetch(:patient_id_source)} as patient_id",
            "#{subquery.fetch(:team_id_source)} as team_id"
          )
          .distinct
          .map { [it.patient_id, it.team_id] }
      end
  end
end
