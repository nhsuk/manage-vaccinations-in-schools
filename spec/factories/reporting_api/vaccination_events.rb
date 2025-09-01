# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_vaccination_events
#
#  id                                               :bigint           not null, primary key
#  event_timestamp                                  :datetime
#  event_timestamp_academic_year                    :integer
#  event_timestamp_day                              :integer
#  event_timestamp_month                            :integer
#  event_timestamp_year                             :integer
#  event_type                                       :string
#  gp_practice_address_postcode                     :string
#  gp_practice_address_town                         :string
#  gp_practice_name                                 :string
#  location_address_postcode                        :string
#  location_address_town                            :string
#  location_gias_local_authority_code               :string
#  location_local_authority_gss_code                :string
#  location_local_authority_mhclg_code              :string
#  location_local_authority_short_name              :string
#  location_name                                    :string
#  location_type                                    :string
#  organisation_name                                :string
#  organisation_ods_code                            :string
#  patient_address_postcode                         :string
#  patient_address_town                             :string
#  patient_birth_academic_year                      :integer
#  patient_date_of_birth                            :date
#  patient_date_of_death                            :date
#  patient_gender_code                              :string
#  patient_home_educated                            :boolean
#  patient_local_authority_from_postcode_gss_code   :string
#  patient_local_authority_from_postcode_mhclg_code :string
#  patient_local_authority_from_postcode_short_name :string
#  patient_nhs_number                               :string
#  patient_school_address_postcode                  :string
#  patient_school_address_town                      :string
#  patient_school_gias_local_authority_code         :string
#  patient_school_local_authority_gss_code          :string
#  patient_school_local_authority_mchlg_code        :string
#  patient_school_local_authority_short_name        :string
#  patient_school_name                              :string
#  patient_school_type                              :string
#  patient_year_group                               :integer
#  programme_type                                   :string
#  source_type                                      :string
#  team_name                                        :string
#  vaccination_record_delivery_method               :string
#  vaccination_record_dose_sequence                 :integer
#  vaccination_record_outcome                       :string
#  vaccination_record_performed_at                  :datetime
#  vaccination_record_performed_by_family_name      :string
#  vaccination_record_performed_by_given_name       :string
#  vaccination_record_uuid                          :uuid
#  vaccine_brand                                    :text
#  vaccine_discontinued                             :boolean          default(FALSE)
#  vaccine_dose_volume_ml                           :decimal(, )
#  vaccine_full_dose                                :boolean
#  vaccine_manufacturer                             :text
#  vaccine_method                                   :string
#  vaccine_nivs_name                                :text
#  vaccine_snomed_product_code                      :string
#  vaccine_snomed_product_term                      :string
#  created_at                                       :datetime         not null
#  updated_at                                       :datetime         not null
#  gp_practice_id                                   :bigint
#  location_id                                      :bigint
#  organisation_id                                  :bigint
#  patient_id                                       :bigint
#  patient_school_id                                :bigint
#  programme_id                                     :bigint
#  source_id                                        :bigint
#  team_id                                          :bigint
#  vaccination_record_batch_id                      :bigint
#  vaccination_record_performed_by_user_id          :bigint
#  vaccination_record_programme_id                  :bigint
#  vaccination_record_session_id                    :bigint
#  vaccine_id                                       :bigint
#  vaccine_programme_id                             :bigint
#
# Indexes
#
#  index_reporting_api_vaccination_events_on_source  (source_type,source_id)
#  ix_rpt_vac_event_ac_year_month                    (event_timestamp_academic_year,event_timestamp_month)
#  ix_rpt_vac_event_source_type_id                   (source_type,source_id)
#  ix_rpt_vac_event_tstamp                           (event_timestamp)
#  ix_rve_team_acyr_month                            (team_id,event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_tstamp_year_month_prog_type                (event_timestamp_academic_year,event_timestamp_month,programme_id,event_type)
#
FactoryBot.define do
  factory :reporting_api_vaccination_event,
          class: "ReportingAPI::VaccinationEvent" do
    transient do
      outcome { "administered" }
      year_group { 9 }
      for_patient do
        build(:patient, year_group: year_group, random_nhs_number: true)
      end
      programme do
        Programme.find_by(type: "flu") || build(:programme, type: "flu")
      end
      location do
        Location.order("RANDOM()").first || build(:location)
      end
      session do
        build(:session, location: location)
      end
    end

    source do
      build(
        :vaccination_record,
        patient: for_patient,
        programme: programme,
        outcome: outcome,
        session: session,
        location: location,
        performed_by: User.first
      )
    end
    patient { for_patient }
    vaccination_record_outcome { outcome }
    patient_year_group { year_group }
  end
end
