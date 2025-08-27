# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_consent_events
#
#  id                                       :bigint           not null, primary key
#  consent_invalidated_at                   :datetime
#  consent_notification_sent_at             :datetime
#  consent_notification_type                :string
#  consent_notify_parents                   :boolean
#  consent_reason_for_refusal               :string
#  consent_response                         :string
#  consent_route                            :string
#  consent_status_academic_year             :integer
#  consent_status_status                    :string
#  consent_status_vaccine_methods           :integer          is an Array
#  consent_submitted_at                     :datetime
#  consent_vaccine_methods                  :integer          is an Array
#  consent_withdrawn_at                     :datetime
#  event_timestamp                          :datetime
#  event_timestamp_academic_year            :integer
#  event_timestamp_day                      :integer
#  event_timestamp_month                    :integer
#  event_timestamp_year                     :integer
#  event_type                               :string
#  organisation_ods_code                    :string
#  parent_contact_method_type               :string
#  parent_phone_receive_updates             :boolean
#  parent_relationship_other_name           :string
#  parent_relationship_type                 :string
#  patient_address_postcode                 :string
#  patient_address_town                     :string
#  patient_birth_academic_year              :integer
#  patient_date_of_death                    :date
#  patient_gender_code                      :string
#  patient_home_educated                    :boolean
#  patient_local_authority_gias_code        :string
#  patient_local_authority_gss_code         :string
#  patient_local_authority_mhclg_code       :string
#  patient_local_authority_short_name       :string
#  patient_school_address_postcode          :string
#  patient_school_address_town              :string
#  patient_school_gias_establishment_number :integer
#  patient_school_gias_local_authority_code :integer
#  patient_year_group                       :integer
#  programme_type                           :string
#  source_type                              :string
#  team_name                                :string
#  vaccine_brand                            :text
#  vaccine_discontinued                     :boolean
#  vaccine_dose_volume_ml                   :decimal(, )
#  vaccine_full_dose                        :boolean
#  vaccine_manufacturer                     :text
#  vaccine_method                           :string
#  vaccine_nivs_name                        :text
#  vaccine_snomed_product_code              :string
#  vaccine_snomed_product_term              :string
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  consent_notification_id                  :integer
#  consent_organisation_id                  :bigint
#  consent_parent_id                        :bigint
#  organisation_id                          :bigint
#  patient_id                               :bigint
#  patient_school_id                        :bigint
#  programme_id                             :bigint
#  source_id                                :bigint
#  team_id                                  :bigint
#  vaccine_id                               :bigint
#  vaccine_programme_id                     :bigint
#
# Indexes
#
#  index_reporting_api_consent_events_on_source      (source_type,source_id)
#  ix_rpt_consent_event_ac_year_month                (event_timestamp_academic_year,event_timestamp_month)
#  ix_rpt_consent_event_tstamp                       (event_timestamp)
#  ix_rpt_consent_event_tstamp_year_month_prog_type  (event_timestamp_academic_year,event_timestamp_month,programme_id,event_type)
#  ix_rpt_consent_source_type_id                     (source_type,source_id)
#
class ReportingAPI::ConsentEvent < ApplicationRecord
  include DenormalizingConcern
  include ReportingAPI::EventConcern
end
