class AddReportableEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reportable_events do |t|
      t.string      :event_type
      t.datetime    :event_timestamp
      t.integer     :event_timestamp_year
      t.integer     :event_timestamp_month
      t.integer     :event_timestamp_day
      

      t.references  :source, polymorphic: true

      t.bigint  :patient_id
      t.date    :patient_date_of_birth
      t.string  :patient_nhs_number
      
      
      t.string  :patient_address_town
      t.string  :patient_address_postcode
      t.integer :patient_gender_code
      t.boolean :patient_home_educated
      t.date    :patient_date_of_death
      t.integer :patient_birth_academic_year
      
      t.bigint  :school_id
      t.string  :school_name
      t.string  :school_address_town
      t.string  :school_address_postcode
      t.bigint  :gp_practice_id
      t.string  :gp_practice_name
      t.string  :gp_practice_address_town
      t.string  :gp_practice_address_postcode

      t.bigint  :team_id
      t.string  :team_name
      t.bigint  :organisation_id
      t.string  :organisation_ods_code
      t.string  :organisation_name

      t.integer :vaccination_record_outcome
      t.bigint  :vaccination_record_batch_id
      t.integer :vaccination_record_delivery_method
      t.bigint  :vaccination_record_performed_by_user_id
      t.string  :vaccination_record_performed_by_given_name
      t.string  :vaccination_record_performed_by_family_name
      t.integer :vaccination_record_dose_sequence
      t.uuid    :vaccination_record_uuid
      t.datetime :vaccination_record_performed_at
      t.bigint  :vaccination_record_programme_id
      t.bigint  :vaccination_record_session_id

      t.bigint  :vaccine_id
      t.text    :vaccine_brand
      t.integer :vaccine_method
      t.text    :vaccine_manufacturer
      t.decimal :vaccine_dose_volume_ml
      t.string  :vaccine_snomed_product_code
      t.string  :vaccine_snomed_product_term
      t.text    :vaccine_nivs_name
      t.boolean :vaccine_discontinued, default: false
      t.bigint  :vaccine_programme_id
      t.boolean :vaccine_full_dose
      
      t.timestamps
    end
  end
end
