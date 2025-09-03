# frozen_string_literal: true

class AppImportsNavigationComponent < ViewComponent::Base
  def initialize(active:)
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

      if policy(:notices).index?
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

  delegate :import_issues_count, :policy, :policy_scope, to: :helpers

  def issues_text
    safe_join(
      ["Import issues", " ", render(AppCountComponent.new(import_issues_count))]
    )
  end

  def notices_text
    count = ImportantNotices.call(patient_scope: policy_scope(Patient)).length
    safe_join(["Important notices", " ", render(AppCountComponent.new(count))])
  end
end
