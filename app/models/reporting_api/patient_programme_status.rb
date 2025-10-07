# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_patient_programme_statuses
#
#  id                                         :text             primary key
#  academic_year                              :integer
#  has_any_vaccination                        :boolean
#  most_recent_vaccination_month              :decimal(, )
#  most_recent_vaccination_year               :decimal(, )
#  patient_gender_code                        :integer
#  patient_local_authority_code               :string
#  patient_school_local_authority_code        :string
#  patient_year_group                         :integer
#  programme_type                             :string
#  sais_vaccinations_count                    :bigint
#  team_name                                  :text
#  vaccinated_by_sais_current_year            :boolean
#  vaccinated_elsewhere_declared_current_year :boolean
#  vaccinated_elsewhere_recorded_current_year :boolean
#  vaccinated_in_previous_years               :boolean
#  organisation_id                            :bigint
#  patient_id                                 :bigint
#  programme_id                               :bigint
#  team_id                                    :bigint
#
# Indexes
#
#  ix_rapi_pps_id              (id) UNIQUE
#  ix_rapi_pps_org_year_prog   (organisation_id,academic_year,programme_type)
#  ix_rapi_pps_prog_team_year  (programme_id,team_id,academic_year)
#  ix_rapi_pps_school_la_prog  (patient_school_local_authority_code,programme_type)
#  ix_rapi_pps_team_year       (team_id,academic_year)
#  ix_rapi_pps_year_prog_type  (academic_year,programme_type)
#
class ReportingAPI::PatientProgrammeStatus < ApplicationRecord
  self.primary_key = :id

  belongs_to :patient
  belongs_to :programme
  belongs_to :team
  belongs_to :organisation

  scope :for_academic_year, ->(academic_year) { where(academic_year:) }
  scope :for_programme_type, ->(programme_type) { where(programme_type:) }
  scope :for_team, ->(team_id) { where(team_id:) }
  scope :for_organisation, ->(organisation_id) { where(organisation_id:) }
  scope :for_gender, ->(patient_gender_code) { where(patient_gender_code:) }
  scope :for_year_group, ->(patient_year_group) { where(patient_year_group:) }
  scope :for_school_local_authority, ->(patient_school_local_authority_code) {
      where(patient_school_local_authority_code:)
    }
  scope :for_local_authority, ->(patient_local_authority_code) {
      where(patient_local_authority_code:)
    }

  def readonly? = true

  def self.refresh!(concurrently: true)
    Scenic.database.refresh_materialized_view(table_name, concurrently:, cascade: false)
  end

  def self.cohort_count
    distinct.count(:patient_id)
  end

  def self.vaccinated_count
    where(has_any_vaccination: true).distinct.count(:patient_id)
  end

  def self.not_vaccinated_count
    cohort_count - vaccinated_count
  end

  def self.vaccinated_by_sais_count
    where(vaccinated_by_sais_current_year: true).distinct.count(:patient_id)
  end

  def self.vaccinated_elsewhere_declared_count
    where(vaccinated_elsewhere_declared_current_year: true).distinct.count(:patient_id)
  end

  def self.vaccinated_elsewhere_recorded_count
    where(vaccinated_elsewhere_recorded_current_year: true).distinct.count(:patient_id)
  end

  def self.vaccinated_previously_count
    where(vaccinated_in_previous_years: true).distinct.count(:patient_id)
  end

  def self.vaccinations_given_count
    sum(:sais_vaccinations_count)
  end

  def self.monthly_vaccinations_given
    where(vaccinated_by_sais_current_year: true)
      .where.not(most_recent_vaccination_month: nil)
      .group(:most_recent_vaccination_year, :most_recent_vaccination_month)
      .sum(:sais_vaccinations_count)
      .map { |(year, month), count|
      {
        year: year.to_i, month: Date::MONTHNAMES[month.to_i], count:,
      }
    }
      .sort_by { [it[:year], Date::MONTHNAMES.index(it[:month])] }
  end
end
