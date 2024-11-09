# frozen_string_literal: true

class AppProgrammeNavigationComponent < ViewComponent::Base
  attr_reader :programme, :organisation, :active

  def initialize(programme, organisation:, active:)
    super

    @programme = programme
    @organisation = organisation
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
        href: programme_patients_path(programme),
        text: I18n.t("patients.index.title"),
        selected: active == :patients
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
    vaccination_records_with_issues =
      helpers
        .policy_scope(VaccinationRecord)
        .where(programme:)
        .with_pending_changes
        .distinct

    patients_with_issues = helpers.policy_scope(Patient).with_pending_changes

    unique_import_issues =
      (vaccination_records_with_issues + patients_with_issues).uniq do |record|
        record.is_a?(VaccinationRecord) ? record.patient : record
      end

    base_text = I18n.t("import_issues.index.title")
    count = unique_import_issues.count

    safe_join([base_text, " ", render(AppCountComponent.new(count:))])
  end
end
