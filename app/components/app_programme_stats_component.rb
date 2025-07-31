# frozen_string_literal: true

class AppProgrammeStatsComponent < ViewComponent::Base
  def initialize(programme, academic_year:, patients:)
    super

    @programme = programme
    @academic_year = academic_year
    @patients = patients
  end

  delegate :count, to: :patients, prefix: true

  def vaccinations_count
    helpers
      .policy_scope(VaccinationRecord)
      .for_academic_year(academic_year)
      .where(patient: patients, programme:)
      .count
  end

  def consent_notifications_count
    helpers
      .policy_scope(ConsentNotification)
      .has_programme(programme)
      .for_academic_year(academic_year)
      .where(patient: patients)
      .count
  end

  private

  attr_reader :programme, :academic_year, :patients
end
