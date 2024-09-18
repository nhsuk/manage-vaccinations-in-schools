# frozen_string_literal: true

class AppProgrammeNavigationComponent < ViewComponent::Base
  attr_reader :programme, :active

  def initialize(programme, active:)
    super

    @programme = programme
    @active = active
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        text: "Overview",
        href: programme_path(programme),
        selected: active == :overview
      )
      nav.with_item(
        text: I18n.t("programmes.patients.title"),
        href: patients_programme_path(programme),
        selected: active == :patients
      )
      nav.with_item(
        text: "School sessions",
        href: sessions_programme_path(programme),
        selected: active == :sessions
      )
      nav.with_item(
        text: I18n.t("vaccination_records.index.title"),
        href: programme_vaccination_records_path(programme),
        selected: active == :vaccination_records
      )
      nav.with_item(
        text: I18n.t("immunisation_imports.index.title"),
        href: programme_immunisation_imports_path(programme),
        selected: active == :immunisation_imports
      )
      nav.with_item(
        text: I18n.t("import_issues.index.title"),
        href: programme_import_issues_path(programme),
        selected: active == :import_issues
      )
    end
  end
end
