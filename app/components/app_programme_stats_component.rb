# frozen_string_literal: true

class AppProgrammeStatsComponent < ViewComponent::Base
  def initialize(programme:)
    super
    @programme = programme
  end

  def patients_count
    helpers.policy_scope(Patient).in_programmes([@programme]).count
  end

  def vaccinations_count
    helpers.policy_scope(VaccinationRecord).where(programme: @programme).count
  end

  def consent_notifications_count
    @programme.consent_notifications.has_programme(@programme).count
  end
end
