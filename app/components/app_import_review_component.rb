# frozen_string_literal: true

class AppImportReviewComponent < ViewComponent::Base
  def initialize(
    import:,
    new_records:,
    auto_matched_records:,
    import_issues:,
    school_moves:
  )
    @import = import
    @new_records = new_records.sort_by(&:row_number)
    @auto_matched_records = auto_matched_records.sort_by(&:row_number)
    @import_issues = import_issues.sort_by(&:row_number)
    @school_moves = school_moves
  end

  def call
    helpers.safe_join(
      [
        render_section(
          title: "New records",
          description: new_records_message,
          summary: pluralize(@new_records.count, "new record"),
          changesets: @new_records
        ) do
          render(
            AppImportReviewRecordsSummaryComponent.new(changesets: @new_records)
          )
        end,
        render_section(
          title: "Records already in Mavis",
          description: auto_matched_message,
          summary:
            "#{pluralize(@auto_matched_records.count, "record")} already in Mavis",
          changesets: @auto_matched_records
        ) do
          render(
            AppImportReviewRecordsSummaryComponent.new(
              changesets: @auto_matched_records
            )
          )
        end,
        render_section(
          title:
            "Close matches to existing records - will need review after import",
          description: import_issues_message,
          summary:
            "#{pluralize(@import_issues.count, "close match")} to existing records",
          changesets: @import_issues
        ) do
          render(
            AppImportReviewIssuesSummaryComponent.new(
              changesets: @import_issues
            )
          )
        end,
        render_section(
          title: "School moves - will need review after import",
          description: school_moves_message,
          summary: pluralize(@school_moves.count, "school move"),
          changesets: @school_moves
        ) do
          render(
            AppImportReviewSchoolMovesSummaryComponent.new(
              changesets: @school_moves
            )
          )
        end,
        helpers.tag.hr(
          class:
            "nhsuk-section-break nhsuk-section-break--visible nhsuk-section-break--l"
        ),
        render_button_group
      ].compact
    )
  end

  private

  def new_records_message
    count = @new_records.count
    "This upload includes #{pluralize(count, "new record")} that " \
      "#{count > 1 ? "are" : "is"} not currently in Mavis. " \
      "If you approve the upload, " \
      "#{count > 1 ? "these records" : "this record"} will be added to Mavis."
  end

  def auto_matched_message
    count = @auto_matched_records.count
    "This upload includes #{pluralize(count, "record")} that already " \
      "#{count > 1 ? "exist" : "exists"} in Mavis. " \
      "If you approve the upload, any additional information will be added to " \
      "the existing #{count > 1 ? "records" : "record"}."
  end

  def import_issues_message
    count = @import_issues.count
    "This upload includes #{pluralize(count, "record")} that " \
      "#{count > 1 ? "are close matches to existing records" : "is a close match to an existing record"} " \
      "in Mavis. If you approve the upload, any differences will be flagged as " \
      "import issues needing review."
  end

  def school_moves_message
    count = @school_moves.count
    "This upload includes #{count > 1 ? "children" : "child"} with a different school to " \
      "the one on their Mavis record. If you approve the upload, these will be flagged as " \
      "school moves needing review."
  end

  def cancel_button_text
    @import.in_re_review? ? "Ignore changes" : "Cancel and delete upload"
  end

  def approve_button_text
    if @import.in_re_review?
      "Approve and import changed records"
    else
      "Approve and import records"
    end
  end

  def render_section(title:, description:, summary:, changesets:, &block)
    return if changesets.blank?

    helpers.safe_join(
      [
        helpers.content_tag(:h2, title, class: "nhsuk-heading-m"),
        helpers.content_tag(:p, description, class: "nhsuk-u-reading-width"),
        helpers.content_tag(:details, class: "nhsuk-details nhsuk-expander") do
          helpers.safe_join(
            [
              helpers.content_tag(
                :summary,
                class: "nhsuk-details__summary",
                data: {
                  module: "app-sticky"
                }
              ) do
                helpers.content_tag(
                  :span,
                  summary,
                  class: "nhsuk-details__summary-text"
                )
              end,
              helpers.content_tag(:div, class: "nhsuk-details__text", &block)
            ]
          )
        end
      ]
    )
  end

  def render_button_group
    helpers.content_tag(:div, class: "nhsuk-button-group") do
      helpers.safe_join(
        [
          helpers.govuk_button_to(
            approve_button_text,
            polymorphic_path([:approve, @import]),
            method: :post
          ),
          helpers.govuk_button_to(
            cancel_button_text,
            polymorphic_path([:cancel, @import]),
            secondary: true,
            method: :post
          )
        ]
      )
    end
  end
end
