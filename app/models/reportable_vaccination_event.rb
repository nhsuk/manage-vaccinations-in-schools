# frozen_string_literal: true

# == Schema Information
#
# Table name: reportable_vaccination_events
#
#  id                                          :bigint           not null, primary key
#  event_timestamp                             :datetime
#  event_timestamp_academic_year               :integer
#  event_timestamp_day                         :integer
#  event_timestamp_month                       :integer
#  event_timestamp_year                        :integer
#  event_type                                  :string
#  gp_practice_address_postcode                :string
#  gp_practice_address_town                    :string
#  gp_practice_name                            :string
#  organisation_name                           :string
#  organisation_ods_code                       :string
#  patient_address_postcode                    :string
#  patient_address_town                        :string
#  patient_birth_academic_year                 :integer
#  patient_date_of_birth                       :date
#  patient_date_of_death                       :date
#  patient_gender_code                         :integer
#  patient_home_educated                       :boolean
#  patient_nhs_number                          :string
#  patient_year_group                          :integer
#  programme_type                              :string
#  school_address_postcode                     :string
#  school_address_town                         :string
#  school_name                                 :string
#  source_type                                 :string
#  team_name                                   :string
#  vaccination_record_delivery_method          :string
#  vaccination_record_delivery_site            :string
#  vaccination_record_dose_sequence            :integer
#  vaccination_record_outcome                  :string
#  vaccination_record_performed_at             :datetime
#  vaccination_record_performed_by_family_name :string
#  vaccination_record_performed_by_given_name  :string
#  vaccination_record_uuid                     :uuid
#  vaccine_brand                               :text
#  vaccine_discontinued                        :boolean          default(FALSE)
#  vaccine_dose_volume_ml                      :decimal(, )
#  vaccine_full_dose                           :boolean
#  vaccine_manufacturer                        :text
#  vaccine_method                              :integer
#  vaccine_nivs_name                           :text
#  vaccine_snomed_product_code                 :string
#  vaccine_snomed_product_term                 :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  gp_practice_id                              :bigint
#  organisation_id                             :bigint
#  patient_id                                  :bigint
#  programme_id                                :bigint
#  school_id                                   :bigint
#  source_id                                   :bigint
#  team_id                                     :bigint
#  vaccination_record_batch_id                 :bigint
#  vaccination_record_performed_by_user_id     :bigint
#  vaccination_record_programme_id             :bigint
#  vaccination_record_session_id               :bigint
#  vaccine_id                                  :bigint
#  vaccine_programme_id                        :bigint
#
# Indexes
#
#  index_reportable_events_on_source                     (source_type,source_id)
#  ix_rpt_vaccination_event_ac_year_month                (event_timestamp_academic_year,event_timestamp_month)
#  ix_rpt_vaccination_event_tstamp                       (event_timestamp)
#  ix_rpt_vaccination_event_tstamp_year_month_prog_type  (event_timestamp_academic_year,event_timestamp_month,programme_id,event_type)
#  ix_rpt_vaccination_source_type_id                     (source_type,source_id)
#
class ReportableVaccinationEvent < ApplicationRecord
  include DenormalizingConcern
  include ReportableEventMethods

  # enum :event_type, VaccinationRecord.outcomes,  validate: true
end
