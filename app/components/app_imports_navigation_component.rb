# frozen_string_literal: true

class AppImportsNavigationComponent < ViewComponent::Base
  def initialize(active:)
    super

    @active = active
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: imports_path,
        text: "Recent imports",
        selected: active == :index
      )

      nav.with_item(
        href: imports_issues_path,
        text: issues_text,
        selected: active == :issues
      )

      if helpers.policy(:notices).index?
        nav.with_item(
          href: imports_notices_path,
          text: notices_text,
          selected: active == :notices
        )
      end
    end
  end

  private

  attr_reader :active

  def issues_text
    vaccination_records_with_issues =
      helpers.policy_scope(VaccinationRecord).with_pending_changes.distinct

    patients_with_issues = helpers.policy_scope(Patient).with_pending_changes

    unique_import_issues =
      (vaccination_records_with_issues + patients_with_issues).uniq do |record|
        record.is_a?(VaccinationRecord) ? record.patient_id : record.id
      end

    count = unique_import_issues.count

    safe_join(["Import issues", " ", render(AppCountComponent.new(count:))])
  end

  def notices_text
    count = helpers.policy_scope(Patient).with_notice.count

    safe_join(["Important notices", " ", render(AppCountComponent.new(count:))])
  end
end
