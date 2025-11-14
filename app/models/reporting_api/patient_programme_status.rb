# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_patient_programme_statuses
#
#  id                                         :text             primary key
#  academic_year                              :integer
#  child_refused_vaccination_current_year     :boolean
#  consent_status                             :integer
#  consent_vaccine_methods                    :integer          is an Array
#  has_any_vaccination                        :boolean
#  most_recent_vaccination_month              :decimal(, )
#  most_recent_vaccination_year               :decimal(, )
#  parent_refused_consent_current_year        :boolean
#  patient_gender                             :text
#  patient_local_authority_code               :string
#  patient_school_local_authority_code        :string
#  patient_school_name                        :text
#  patient_school_urn                         :string
#  patient_year_group                         :integer
#  programme_type                             :string
#  sais_vaccinations_count                    :bigint
#  team_name                                  :text
#  vaccinated_by_sais_current_year            :boolean
#  vaccinated_elsewhere_declared_current_year :boolean
#  vaccinated_elsewhere_recorded_current_year :boolean
#  vaccinated_in_previous_years               :boolean
#  vaccinated_injection_current_year          :boolean
#  vaccinated_nasal_current_year              :boolean
#  organisation_id                            :bigint
#  patient_id                                 :bigint
#  patient_school_id                          :bigint
#  programme_id                               :bigint
#  session_location_id                        :bigint
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
  scope :for_school_local_authority,
        ->(patient_school_local_authority_code) do
          where(patient_school_local_authority_code:)
        end
  scope :for_local_authority,
        ->(patient_local_authority_code) do
          where(patient_local_authority_code:)
        end

  scope :consent_given, -> { where(consent_status: 1) }
  scope :consent_refused, -> { where(consent_status: 2) }
  scope :consent_no_response, -> { where(consent_status: [0, nil]) }
  scope :consent_conflicts, -> { where(consent_status: 3) }
  scope :parent_refused_consent,
        -> { where(parent_refused_consent_current_year: true) }
  scope :child_refused_vaccination,
        -> { where(child_refused_vaccination_current_year: true) }

  def readonly? = true

  def self.with_aggregate_metrics
    select(
      "COUNT(DISTINCT patient_id)" \
        "AS cohort",
      "COUNT(DISTINCT CASE WHEN has_any_vaccination = true THEN patient_id END)" \
        "AS vaccinated",
      "COUNT(DISTINCT CASE WHEN has_any_vaccination = false THEN patient_id END)" \
        "AS not_vaccinated",
      "COUNT(DISTINCT CASE WHEN vaccinated_by_sais_current_year = true THEN patient_id END)" \
        "AS vaccinated_by_sais",
      "COUNT(DISTINCT CASE WHEN vaccinated_elsewhere_declared_current_year = true THEN patient_id END)" \
        "AS vaccinated_elsewhere_declared",
      "COUNT(DISTINCT CASE WHEN vaccinated_elsewhere_recorded_current_year = true THEN patient_id END)" \
        "AS vaccinated_elsewhere_recorded",
      "COUNT(DISTINCT CASE WHEN vaccinated_in_previous_years = true THEN patient_id END)" \
        "AS vaccinated_previously",
      "COUNT(DISTINCT CASE WHEN consent_status = 1 THEN patient_id END)" \
        "AS consent_given",
      "COUNT(DISTINCT CASE WHEN consent_status = 0 OR consent_status IS NULL THEN patient_id END)" \
        "AS consent_no_response",
      "COUNT(DISTINCT CASE WHEN consent_status = 3 THEN patient_id END)" \
        "AS consent_conflicts",
      "COUNT(DISTINCT CASE WHEN parent_refused_consent_current_year = true THEN patient_id END)" \
        "AS parent_refused_consent",
      "COUNT(DISTINCT CASE WHEN child_refused_vaccination_current_year = true THEN patient_id END)" \
        "AS child_refused_vaccination"
    )
  end

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
    where(has_any_vaccination: true).distinct.count(:patient_id)
  end

  def self.not_vaccinated_count
    cohort_count - vaccinated_count
  end

  def self.vaccinated_by_sais_count
    where(vaccinated_by_sais_current_year: true).distinct.count(:patient_id)
  end

  def self.vaccinated_elsewhere_declared_count
    where(vaccinated_elsewhere_declared_current_year: true).distinct.count(
      :patient_id
    )
  end

  def self.vaccinated_elsewhere_recorded_count
    where(vaccinated_elsewhere_recorded_current_year: true).distinct.count(
      :patient_id
    )
  end

  def self.vaccinated_previously_count
    where(vaccinated_in_previous_years: true).distinct.count(:patient_id)
  end

  def self.vaccinations_given_count
    sum(:sais_vaccinations_count)
  end

  def self.monthly_vaccinations_given
    months =
      where(vaccinated_by_sais_current_year: true)
        .where.not(most_recent_vaccination_month: nil)
        .group(:most_recent_vaccination_year, :most_recent_vaccination_month)
        .sum(:sais_vaccinations_count)
        .map do |(year, month), count|
          { year: year.to_i, month: Date::MONTHNAMES[month.to_i], count: }
        end
    months.sort_by! { [it[:year], Date::MONTHNAMES.index(it[:month])] }
    months
  end

  def self.consent_given_count
    consent_given.distinct.count(:patient_id)
  end

  def self.consent_no_response_count
    consent_no_response.distinct.count(:patient_id)
  end

  def self.consent_conflicts_count
    consent_conflicts.distinct.count(:patient_id)
  end

  def self.parent_refused_consent_count
    parent_refused_consent.distinct.count(:patient_id)
  end

  def self.child_refused_vaccination_count
    child_refused_vaccination.distinct.count(:patient_id)
  end
end
