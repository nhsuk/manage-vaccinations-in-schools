# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_totals
#
#  id                                  :text             primary key
#  academic_year                       :integer
#  has_already_vaccinated_consent      :boolean
#  is_archived                         :boolean
#  patient_gender                      :integer
#  patient_local_authority_code        :string
#  patient_school_local_authority_code :string
#  patient_year_group                  :integer
#  programme_type                      :enum
#  status                              :integer
#  patient_id                          :bigint
#  session_location_id                 :bigint
#  team_id                             :bigint
#
# Indexes
#
#  ix_rapi_totals_id                     (id) UNIQUE
#  ix_rapi_totals_session_loc            (session_location_id)
#  ix_rapi_totals_team_year_prog_status  (team_id,academic_year,programme_type,status)
#  ix_rapi_totals_year_group             (patient_year_group)
#
class ReportingAPI::Total < ApplicationRecord
  self.primary_key = :id

  belongs_to :patient
  belongs_to :team

  VACCINATED_STATUSES = Patient::ProgrammeStatus::VACCINATED_STATUSES.values

  scope :not_archived, -> { where(is_archived: false) }
  scope :vaccinated,
        -> do
          where(status: VACCINATED_STATUSES).or(
            where(has_already_vaccinated_consent: true)
          )
        end

  def readonly? = true

  def self.refresh!(concurrently: true)
    Scenic.database.refresh_materialized_view(
      table_name,
      concurrently:,
      cascade: false
    )
  end

  def self.cohort_count
    distinct.count(:patient_id)
  end

  def self.vaccinated_count
    vaccinated.distinct.count(:patient_id)
  end
end
