# frozen_string_literal: true

class AppProgrammeStatsComponent < ViewComponent::Base
  def initialize(programme, academic_year:, patient_ids:)
    @programme = programme
    @academic_year = academic_year
    @patient_ids = patient_ids
  end

  def patients_count = patient_ids.length

  def vaccinations_count
    helpers
      .policy_scope(VaccinationRecord)
      .administered
      .where_programme(programme)
      .where(patient_id: patient_ids)
      .count
  end

  def consent_notifications_count
    helpers
      .policy_scope(ConsentNotification)
      .has_all_programmes_of([programme])
      .joins(session: :team_location)
      .where(team_location: { academic_year: })
      .where(patient_id: patient_ids)
      .count
  end

  private

  attr_reader :programme, :academic_year, :patient_ids
end
