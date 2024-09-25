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
        text: "Overview",
        selected: active == :overview
      )

      nav.with_item(
        href: programme_cohorts_path(programme),
        text: I18n.t("cohorts.index.title"),
        selected: active == :cohorts
      )

      nav.with_item(
        href: sessions_programme_path(programme),
        text: I18n.t("sessions.index.title"),
        selected: active == :sessions
      )

      nav.with_item(
        href: programme_vaccination_records_path(programme),
        text: I18n.t("vaccination_records.index.title"),
        selected: active == :vaccination_records
      )

      nav.with_item(
        href: programme_imports_path(programme),
        text: I18n.t("imports.index.title"),
        selected: active == :imports
      )

      nav.with_item(
        href: programme_import_issues_path(programme),
        text: import_issues_text,
        selected: active == :import_issues
      )
    end
  end

  private

  def import_issues_text
    count = programme.import_issues.count
    base_text = I18n.t("import_issues.index.title")

    safe_join([base_text, " ", render(AppCountComponent.new(count:))])
  end
end
