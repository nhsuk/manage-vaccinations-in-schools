# frozen_string_literal: true

class AppProgrammeStatsComponent < ViewComponent::Base
  def initialize(programme, academic_year:)
    super

    @programme = programme
    @academic_year = academic_year
  end

  def patients_count
    helpers
      .policy_scope(Patient)
      .in_programmes([@programme], academic_year:)
      .count
  end

  def vaccinations_count
    helpers
      .policy_scope(VaccinationRecord)
      .where(programme:, performed_at: academic_year_date_range)
      .count
  end

  def consent_notifications_count
    helpers
      .policy_scope(ConsentNotification)
      .has_programme(programme)
      .where(sent_at: academic_year_date_range)
      .count
  end

  private

  attr_reader :programme, :academic_year

  def academic_year_date_range = academic_year.to_academic_year_date_range
end
