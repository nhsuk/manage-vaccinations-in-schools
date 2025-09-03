# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_vaccination_events
#
#  id                                               :bigint           not null, primary key
#  event_timestamp                                  :datetime         not null
#  event_timestamp_academic_year                    :integer          not null
#  event_timestamp_day                              :integer          not null
#  event_timestamp_month                            :integer          not null
#  event_timestamp_year                             :integer          not null
#  event_type                                       :string           not null
#  location_address_postcode                        :string
#  location_address_town                            :string
#  location_local_authority_mhclg_code              :string
#  location_local_authority_short_name              :string
#  location_name                                    :string
#  location_type                                    :string
#  organisation_name                                :string
#  organisation_ods_code                            :string
#  patient_address_postcode                         :string
#  patient_address_town                             :string
#  patient_birth_academic_year                      :integer
#  patient_date_of_death                            :date
#  patient_gender_code                              :string
#  patient_home_educated                            :boolean
#  patient_local_authority_from_postcode_mhclg_code :string
#  patient_local_authority_from_postcode_short_name :string
#  patient_school_address_postcode                  :string
#  patient_school_address_town                      :string
#  patient_school_gias_local_authority_code         :integer
#  patient_school_local_authority_mhclg_code        :string
#  patient_school_local_authority_short_name        :string
#  patient_school_name                              :string
#  patient_school_type                              :string
#  patient_year_group                               :integer
#  programme_type                                   :string
#  source_type                                      :string           not null
#  team_name                                        :string
#  vaccination_record_outcome                       :string
#  vaccination_record_performed_at                  :datetime
#  vaccination_record_uuid                          :uuid
#  created_at                                       :datetime         not null
#  updated_at                                       :datetime         not null
#  location_id                                      :bigint
#  organisation_id                                  :bigint
#  patient_id                                       :bigint           not null
#  patient_school_id                                :bigint
#  programme_id                                     :bigint
#  source_id                                        :bigint           not null
#  team_id                                          :bigint
#  vaccination_record_programme_id                  :bigint
#  vaccination_record_session_id                    :bigint
#
# Indexes
#
#  index_reporting_api_vaccination_events_on_source  (source_type,source_id)
#  ix_rve_ac_year_month                              (event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_acyear_month_type                          (event_timestamp_academic_year,event_timestamp_month,event_type)
#  ix_rve_prog_acyear_month                          (programme_id,event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_source_type_id                             (source_type,source_id)
#  ix_rve_team_acyr_month                            (team_id,event_timestamp_academic_year,event_timestamp_month)
#  ix_rve_tstamp                                     (event_timestamp)
#
class ReportingAPI::VaccinationEvent < ApplicationRecord
  include ReportingAPI::DenormalizingConcern
  include ReportingAPI::EventConcern

  def self.with_counts_of_outcomes
    select(
      count_sql_where(
        comparison: "vaccination_record_outcome = 'administered'",
        as: "total_vaccinations_performed"
      )
    )
  end

  def self.with_count_of_patients_vaccinated
    # We want a count of just the distinct patient_ids
    # for whom the outcome was 'administered'.
    # If the outcome was not 'administered', this count should not include them
    select(<<-SQL)
        COUNT(
          DISTINCT(
            CASE WHEN vaccination_record_outcome = 'administered'
            THEN patient_id 
            ELSE NULL 
            END
          )
        ) AS total_patients_vaccinated
      SQL
  end
end
