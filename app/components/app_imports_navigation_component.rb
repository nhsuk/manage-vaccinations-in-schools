# frozen_string_literal: true

class AppImportsNavigationComponent < ViewComponent::Base
  def initialize(active:, team:)
    @active = active
    @team = team
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: imports_path,
        text: "Uploaded files",
        selected: active == :uploaded
      )

      nav.with_item(
        href: imports_issues_path,
        text: issues_text,
        selected: active == :issues
      )

      nav.with_item(
        href: records_imports_path,
        text: "Imported records",
        selected: active == :imported
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

  attr_reader :active, :team

  delegate :policy, :policy_scope, to: :helpers

  def issues_text
    count = TeamCachedCounts.new(team).import_issues
    text_with_count("Upload issues", count)
  end

  def notices_text
    count = ImportantNotices.call(patient_scope: policy_scope(Patient)).length

    text_with_count("Important notices", count)
  end

  def text_with_count(text, count)
    safe_join([text, " ", render(AppCountComponent.new(count))])
  end
end
