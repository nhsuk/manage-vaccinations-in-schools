class AddReportingAPIVaccinationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reporting_api_vaccination_events do |t|
      t.string :event_type
      t.datetime :event_timestamp
      t.integer :event_timestamp_year
      t.integer :event_timestamp_month
      t.integer :event_timestamp_day
      t.integer :event_timestamp_academic_year

      t.references :source, polymorphic: true

      t.bigint :patient_id
      t.date :patient_date_of_birth
      t.string :patient_nhs_number

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
      t.string :patient_school_gias_local_authority_code
      t.string :patient_school_type

      t.string :patient_local_authority_from_postcode_gss_code
      t.string :patient_local_authority_from_postcode_mhclg_code
      t.string :patient_local_authority_from_postcode_short_name

      t.bigint :location_id
      t.string :location_name
      t.string :location_address_town
      t.string :location_address_postcode

      t.string :location_local_authority_gss_code
      t.string :location_local_authority_mhclg_code
      t.string :location_local_authority_short_name
      t.string :location_gias_local_authority_code
      t.string :location_type

      t.bigint :gp_practice_id
      t.string :gp_practice_name
      t.string :gp_practice_address_town
      t.string :gp_practice_address_postcode

      t.bigint :team_id
      t.string :team_name
      t.bigint :organisation_id
      t.string :organisation_ods_code
      t.string :organisation_name

      t.string :vaccination_record_outcome
      t.bigint :vaccination_record_batch_id
      t.string :vaccination_record_delivery_method
      t.bigint :vaccination_record_performed_by_user_id
      t.string :vaccination_record_performed_by_given_name
      t.string :vaccination_record_performed_by_family_name
      t.integer :vaccination_record_dose_sequence
      t.uuid :vaccination_record_uuid
      t.datetime :vaccination_record_performed_at
      t.bigint :vaccination_record_programme_id
      t.bigint :vaccination_record_session_id

      t.bigint :vaccine_id
      t.text :vaccine_brand
      t.string :vaccine_method
      t.text :vaccine_manufacturer
      t.decimal :vaccine_dose_volume_ml
      t.string :vaccine_snomed_product_code
      t.string :vaccine_snomed_product_term
      t.text :vaccine_nivs_name
      t.boolean :vaccine_discontinued, default: false
      t.bigint :vaccine_programme_id
      t.boolean :vaccine_full_dose

      t.bigint :programme_id
      t.string :programme_type

      t.index  [:event_timestamp], name: 'ix_rpt_vac_event_tstamp'
      t.index  [:event_timestamp_academic_year, :event_timestamp_month], name: 'ix_rpt_vac_event_ac_year_month'
      t.index  [:source_type, :source_id], name: 'ix_rpt_vac_event_source_type_id'
      t.index  [:event_timestamp_academic_year, :event_timestamp_month, :programme_id, :event_type], name: 'ix_rve_tstamp_year_month_prog_type'
      t.index  [:team_id, :event_timestamp_academic_year, :event_timestamp_month], name: 'ix_rve_team_acyr_month'
    end
  end
end
