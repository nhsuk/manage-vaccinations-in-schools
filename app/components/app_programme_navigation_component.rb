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
        href: programme_path(programme),
        selected: active == :overview
      ) { "Overview" }

      nav.with_item(
        href: programme_cohorts_path(programme),
        selected: active == :cohorts
      ) { I18n.t("cohorts.index.title") }

      nav.with_item(
        href: sessions_programme_path(programme),
        selected: active == :sessions
      ) { I18n.t("sessions.index.title") }

      nav.with_item(
        href: programme_vaccination_records_path(programme),
        selected: active == :vaccination_records
      ) { I18n.t("vaccination_records.index.title") }

      nav.with_item(
        href: programme_imports_path(programme),
        selected: active == :imports
      ) { I18n.t("imports.index.title") }

      nav.with_item(
        href: programme_import_issues_path(programme),
        selected: active == :import_issues
      ) { import_issues_text }
    end
  end

  private

  def import_issues_text
    count = programme.import_issues.count
    base_text = I18n.t("import_issues.index.title")

    safe_join([base_text, " ", render(AppCountComponent.new(count:))])
  end
end
