class AddReportableConsentEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reportable_consent_events do |t|
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

      t.integer :consent_response
      t.integer :consent_reason_for_refusal
      t.text :consent_notes
      t.integer :consent_route
      t.jsonb :consent_health_answers
      t.bigint :consent_recorded_by_user_id
      t.bigint :consent_parent_id
      t.bigint :consent_organisation_id
      t.datetime :consent_withdrawn_at
      t.datetime :consent_invalidated_at
      t.boolean :consent_notify_parents
      t.datetime :consent_submitted_at
      t.integer :consent_vaccine_methods, array: true

      t.string :parent_full_name
      t.string :parent_email
      t.string :parent_phone
      t.text :parent_contact_method_other_details
      t.datetime :parent_created_at
      t.datetime :parent_updated_at
      t.string :parent_contact_method_type
      t.boolean :parent_phone_receive_updates

      t.string :parent_relationship_type
      t.string :parent_relationship_other_name

      t.string :consent_recorded_by_user_email
      t.string :consent_recorded_by_user_given_name
      t.string :consent_recorded_by_user_family_name
      
      t.bigint :vaccine_id
      t.text :vaccine_brand
      t.integer :vaccine_method
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

      t.timestamps
    end

  end
end
