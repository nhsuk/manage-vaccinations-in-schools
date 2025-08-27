class AddReportingAPIConsentEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reporting_api_consent_events do |t|
      t.string :event_type
      t.datetime :event_timestamp
      t.integer :event_timestamp_year
      t.integer :event_timestamp_month
      t.integer :event_timestamp_day
      t.integer :event_timestamp_academic_year

      t.references :source, polymorphic: true

      t.bigint :patient_id
      t.string :patient_address_town
      t.string :patient_address_postcode
      t.string :patient_gender_code
      t.boolean :patient_home_educated
      t.date :patient_date_of_death
      t.integer :patient_birth_academic_year
      t.integer :patient_year_group

      t.string :patient_local_authority_gss_code
      t.string :patient_local_authority_gias_code
      t.string :patient_local_authority_mhclg_code
      t.string :patient_local_authority_short_name

      t.bigint :patient_school_id
      t.string :patient_school_address_town
      t.string :patient_school_address_postcode
      t.integer :patient_school_gias_local_authority_code
      t.integer :patient_school_gias_establishment_number

      t.string :consent_status_status
      t.integer :consent_status_vaccine_methods, array: true
      t.integer :consent_status_academic_year

      t.integer :consent_notification_id
      t.datetime :consent_notification_sent_at
      t.string :consent_notification_type

      t.string :consent_response
      t.string :consent_reason_for_refusal
      t.string :consent_route
      t.bigint :consent_parent_id
      t.bigint :consent_organisation_id
      t.datetime :consent_withdrawn_at
      t.datetime :consent_invalidated_at
      t.boolean :consent_notify_parents
      t.datetime :consent_submitted_at
      t.integer :consent_vaccine_methods, array: true

      t.string :parent_contact_method_type
      t.boolean :parent_phone_receive_updates

      t.string :parent_relationship_type
      t.string :parent_relationship_other_name

      t.bigint :vaccine_id
      t.text :vaccine_brand
      t.string :vaccine_method
      t.text :vaccine_manufacturer
      t.decimal :vaccine_dose_volume_ml
      t.string :vaccine_snomed_product_code
      t.string :vaccine_snomed_product_term
      t.text :vaccine_nivs_name
      t.boolean :vaccine_discontinued
      t.bigint :vaccine_programme_id
      t.boolean :vaccine_full_dose

      t.bigint :programme_id
      t.string :programme_type

      t.bigint :team_id
      t.string :team_name

      t.bigint :organisation_id
      t.string :organisation_ods_code

      t.timestamps

      t.index [:event_timestamp], name: 'ix_rpt_consent_event_tstamp'
      t.index [:event_timestamp_academic_year, :event_timestamp_month], name: 'ix_rpt_consent_event_ac_year_month'
      t.index [:source_type, :source_id], name: 'ix_rpt_consent_source_type_id'
      t.index [:event_timestamp_academic_year, :event_timestamp_month, :programme_id, :event_type], name: 'ix_rpt_consent_event_tstamp_year_month_prog_type'

    end

  end
end
