# frozen_string_literal: true

class AppProgrammeNavigationComponent < ViewComponent::Base
  def initialize(programme, active:)
    super

    @programme = programme
    @active = active
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: programme_path(programme),
        text: "Overview",
        selected: active == :overview
      )

      nav.with_item(
        href: programme_cohorts_path(programme),
        text: I18n.t("programmes.cohorts.index.title"),
        selected: active == :cohorts
      )

      nav.with_item(
        href: sessions_programme_path(programme),
        text: I18n.t("sessions.index.title"),
        selected: active == :sessions
      )

      nav.with_item(
        href: programme_patients_path(programme),
        text: I18n.t("programmes.patients.index.title"),
        selected: active == :patients
      )

      nav.with_item(
        href: programme_vaccinations_path(programme),
        text: I18n.t("programmes.vaccinations.index.title"),
        selected: active == :vaccinations
      )
    end
  end

  private

  attr_reader :programme, :active
end
