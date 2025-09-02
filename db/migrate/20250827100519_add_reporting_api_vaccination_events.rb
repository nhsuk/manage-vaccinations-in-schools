# frozen_string_literal: true

class AddReportingAPIVaccinationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reporting_api_vaccination_events do |t|
      t.string :event_type, null: false
      t.datetime :event_timestamp, null: false
      t.integer :event_timestamp_year, null: false
      t.integer :event_timestamp_month, null: false
      t.integer :event_timestamp_day, null: false
      t.integer :event_timestamp_academic_year, null: false

      t.references :source, polymorphic: true, null: false

      t.bigint :patient_id, null: false

      t.string :patient_address_town
      t.string :patient_address_postcode
      t.string :patient_gender_code
      t.boolean :patient_home_educated
      t.date :patient_date_of_death
      t.integer :patient_birth_academic_year
      t.integer :patient_year_group

      t.bigint :patient_school_id
      t.string :patient_school_name
      t.string :patient_school_address_town
      t.string :patient_school_address_postcode
      t.integer :patient_school_gias_local_authority_code
      t.string :patient_school_type

      t.string :patient_school_local_authority_mhclg_code
      t.string :patient_school_local_authority_short_name
      t.string :patient_local_authority_from_postcode_mhclg_code
      t.string :patient_local_authority_from_postcode_short_name

      t.bigint :location_id
      t.string :location_name
      t.string :location_address_town
      t.string :location_address_postcode
      t.string :location_type

      t.string :location_local_authority_mhclg_code
      t.string :location_local_authority_short_name

      t.bigint :team_id
      t.string :team_name

      t.bigint :organisation_id
      t.string :organisation_ods_code
      t.string :organisation_name

      t.string :vaccination_record_outcome
      t.uuid :vaccination_record_uuid
      t.datetime :vaccination_record_performed_at
      t.bigint :vaccination_record_programme_id
      t.bigint :vaccination_record_session_id

      t.bigint :programme_id
      t.string :programme_type

      t.timestamps

      t.index [:event_timestamp], name: "ix_rve_tstamp"
      t.index %i[event_timestamp_academic_year event_timestamp_month],
              name: "ix_rve_ac_year_month"
      t.index %i[source_type source_id], name: "ix_rve_source_type_id"
      t.index %i[
                event_timestamp_academic_year
                event_timestamp_month
                event_type
              ],
              name: "ix_rve_acyear_month_type"
      t.index %i[
                programme_id
                event_timestamp_academic_year
                event_timestamp_month
              ],
              name: "ix_rve_prog_acyear_month"
      t.index %i[team_id event_timestamp_academic_year event_timestamp_month],
              name: "ix_rve_team_acyr_month"
    end
  end
end
