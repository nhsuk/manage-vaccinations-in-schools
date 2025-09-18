# frozen_string_literal: true

class Stats::Organisations
  def initialize(organisation:, teams:, programmes:, academic_year:)
    @organisation = organisation
    @teams = teams
    @programmes = programmes
    @academic_year = academic_year
    @patients = build_patients_scope
  end

  def call
    calculate_organisation_stats
  end

  def self.call(...) = new(...).call

  private

  attr_reader :organisation, :teams, :programmes, :academic_year, :patients

  def build_patients_scope
    Patient.distinct.joins_sessions.where(
      sessions: {
        team_id: teams.map(&:id)
      }
    )
  end

  def calculate_organisation_stats
    programme_stats =
      programmes.map do |programme|
        {
          programme_name: programme.type,
          cohort_total: calculate_cohort_total(programme),
          school_total: calculate_school_total(programme),
          consent_stats: calculate_consent_stats(programme),
          comms_stats: calculate_consent_notifications_stats(programme),
          vaccination_stats: calculate_vaccination_stats(programme)
        }
      end

    {
      ods_code: organisation.ods_code,
      team_names: teams.map(&:name).join(", "),
      programme_stats: programme_stats
    }
  end

  def calculate_cohort_total(programme)
    eligible_patients = get_eligible_patients(programme)
    by_year =
      eligible_patients
        .group_by { |p| p.year_group(academic_year: academic_year) }
        .transform_values(&:count)

    { total: eligible_patients.count, years: by_year }
  end

  def calculate_school_total(programme)
    Team
      .where(id: teams.pluck(:id))
      .includes(:schools)
      .flat_map(&:schools)
      .uniq
      .count { |location| location.programmes.include?(programme) }
  end

  def calculate_consent_stats(programme)
    eligible_patients = get_eligible_patients(programme)

    total_consents =
      Consent
        .joins(:team)
        .where(team: teams)
        .where(programme: programme, academic_year: academic_year)
        .distinct
        .count

    patients_with_no_response =
      eligible_patients.has_consent_status(
        :no_response,
        programme: programme,
        academic_year: academic_year
      )

    patients_with_response_given =
      eligible_patients.has_consent_status(
        :given,
        programme: programme,
        academic_year: academic_year
      )

    patients_with_response_refused =
      eligible_patients.has_consent_status(
        :refused,
        programme: programme,
        academic_year: academic_year
      )

    patients_with_response_conflicting =
      eligible_patients.has_consent_status(
        :conflicts,
        programme: programme,
        academic_year: academic_year
      )

    no_response_but_contacted =
      patients_with_no_response.joins(:consent_notifications)

    {
      total_consents: total_consents,
      patients_with_no_response: {
        total: patients_with_no_response.count,
        contacted: no_response_but_contacted.count
      },
      patients_with_response_given: patients_with_response_given.count,
      patients_with_response_refused: patients_with_response_refused.count,
      patients_with_response_conflicting:
        patients_with_response_conflicting.count
    }
  end

  def calculate_consent_notifications_stats(programme)
    eligible_patients = get_eligible_patients(programme)

    comms =
      ConsentNotification
        .joins(session: :team)
        .where(sessions: { team: teams })
        .where(patient_id: eligible_patients.map(&:id))
        .where(sessions: { academic_year: academic_year })
        .has_programme(programme)

    initial_requests = comms.request
    reminders = comms.reminder

    schools_involved =
      comms.joins(:session).distinct.count(:"sessions.location_id")
    patients_with_comms = comms.distinct.count(:patient_id)
    patients_with_requests = initial_requests.distinct.count(:patient_id)
    patients_with_reminders = reminders.distinct.count(:patient_id)

    {
      schools_involved: schools_involved,
      patients_with_comms: patients_with_comms,
      patients_with_requests: patients_with_requests,
      patients_with_reminders: patients_with_reminders
    }
  end

  def calculate_vaccination_stats(programme)
    eligible_patients = get_eligible_patients(programme)

    vaccinated_patients =
      eligible_patients.has_vaccination_status(
        :vaccinated,
        programme: programme,
        academic_year: academic_year
      )

    coverage_count = vaccinated_patients.count

    vaccinated_in_mavis_count =
      VaccinationRecord
        .recorded_in_service
        .for_academic_year(academic_year)
        .where(patient_id: eligible_patients.map(&:id))
        .where(programme_id: programme.id)
        .where(outcome: "administered")
        .distinct
        .count

    coverage_percentage =
      if eligible_patients.count.positive?
        (coverage_count.to_f / eligible_patients.count * 100).round(2)
      else
        0
      end

    {
      coverage_count: coverage_count,
      vaccinated_in_mavis_count: vaccinated_in_mavis_count,
      coverage_percentage: coverage_percentage
    }
  end

  def get_eligible_patients(programme)
    patients.appear_in_programmes([programme], academic_year:)
  end
end
