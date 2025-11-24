# frozen_string_literal: true

class AppImportReviewIssuesSummaryComponent < ViewComponent::Base
  def initialize(changesets: nil)
    @changesets = changesets.sort_by(&:row_number) || []
  end

  def call
    helpers.govuk_table(
      html_attributes: {
        class: "nhsuk-table-responsive"
      }
    ) do |table|
      table.with_head do |head|
        head.with_row do |row|
          row.with_cell(text: "Name and NHS number")
          row.with_cell(text: "Issue to review")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          body.with_row do |row|
            row.with_cell do
              heading =
                tag.span(
                  "Name and NHS number",
                  class: "nhsuk-table-responsive__heading"
                )

              helpers.safe_join(
                [
                  heading,
                  tag.span(
                    FullNameFormatter.call(changeset, context: :internal)
                  ),
                  tag.br,
                  tag.span(
                    helpers.format_nhs_number(changeset.nhs_number),
                    class: "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
                  )
                ]
              )
            end

            row.with_cell do
              heading =
                tag.span(
                  "Issue to review",
                  class: "nhsuk-table-responsive__heading"
                )

              pending_changes = changeset.review_data["pending_changes"] || {}
              issue_groups = helpers.issue_categories_for(pending_changes.keys)

              issue_text =
                if changeset.matched_on_nhs_number?
                  "Matched on NHS number. " \
                    "#{issue_groups.to_sentence.capitalize} #{issue_groups.size == 1 ? "does not" : "do not"} match."
                else
                  "Possible match found. Review and confirm."
                end

              helpers.safe_join([heading, tag.span(issue_text)])
            end
          end
        end
      end
    end
  end
end
