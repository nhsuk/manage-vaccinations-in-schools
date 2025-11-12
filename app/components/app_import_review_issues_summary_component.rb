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
          patient = changeset.patient

          body.with_row do |row|
            row.with_cell do
              heading =
                helpers.content_tag(
                  :span,
                  "Name and NHS number",
                  class: "nhsuk-table-responsive__heading"
                )

              helpers.safe_join(
                [
                  heading,
                  helpers.content_tag(:span, patient.full_name),
                  helpers.tag.br,
                  helpers.content_tag(
                    :span,
                    helpers.patient_nhs_number(patient),
                    class: "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
                  )
                ]
              )
            end

            row.with_cell do
              heading =
                helpers.content_tag(
                  :span,
                  "Issue to review",
                  class: "nhsuk-table-responsive__heading"
                )

              pending_changes = patient.pending_changes
              issue_groups = helpers.issue_categories_for(pending_changes.keys)

              issue_text =
                if changeset.matched_on_nhs_number?
                  "Matched on NHS number. " \
                    "#{issue_groups.to_sentence.capitalize} #{issue_groups.size == 1 ? "does not" : "do not"} match."
                else
                  "Possible match found. Review and confirm."
                end

              helpers.safe_join(
                [heading, helpers.content_tag(:span, issue_text)]
              )
            end
          end
        end
      end
    end
  end
end
