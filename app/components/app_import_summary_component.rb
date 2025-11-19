# frozen_string_literal: true

class AppImportSummaryComponent < ViewComponent::Base
  attr_reader :import

  def initialize(import:)
    @import = import
  end

  def import_type_label
    {
      "ClassImport" => "Class list records",
      "CohortImport" => "Child records",
      "ImmunisationImport" => "Vaccination records"
    }[
      import.class.name
    ]
  end

  def show_approved_reviewers?
    return false unless import.is_a?(PatientImport)
    (import.processed? || import.partially_processed?) &&
      import.reviewed_by_user_ids.present?
  end

  def show_cancelled_reviewer?
    (import.cancelled? || import.partially_processed?) &&
      import.reviewed_by_user_ids.present?
  end

  def approved_reviewers_text
    import.partially_processed? ? approvers_text : all_reviewers_text
  end

  def records_count
    if import.is_a?(PatientImport)
      import.changesets.from_file.count
    else
      import.vaccination_records.count
    end
  end

  private

  def cancelled_reviewer_label
    import.partially_processed? ? "Stopped by" : "Cancelled by"
  end

  def cancelled_reviewer_text
    last_reviewer = import.reviewed_by_user_ids.last
    reviewed_at = import.reviewed_at.last
    re_review_text = import.partially_processed? ? " (re-review)" : ""
    format_reviewer(last_reviewer, reviewed_at) + re_review_text
  end

  def approvers_text
    reviewers = import.reviewed_by_user_ids[0..-2]
    times = import.reviewed_at[0..-2]

    format_reviewers_list(reviewers, times)
  end

  def all_reviewers_text
    format_reviewers_list(import.reviewed_by_user_ids, import.reviewed_at)
  end

  def format_reviewers_list(reviewer_ids, times)
    return "" if reviewer_ids.blank?

    items =
      reviewer_ids.each_with_index.map do |reviewer_id, index|
        re_review_text = index.positive? ? " (re-review)" : ""
        format_reviewer(reviewer_id, times[index]) + re_review_text
      end

    if items.one?
      items.first
    else
      tag.ul(class: "nhsuk-list nhsuk-list--bullet") do
        safe_join(items.map { |item| tag.li(item) })
      end
    end
  end

  def format_reviewer(user_id, reviewed_at)
    user = User.find(user_id)
    time_text = reviewed_at&.to_fs(:long)
    "#{user.full_name} on #{time_text} "
  end
end
