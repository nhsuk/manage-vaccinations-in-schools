# frozen_string_literal: true

class AppImportReviewRecordsSummaryComponent < ViewComponent::Base
  def initialize(changesets:)
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
          row.with_cell(text: "CSV file row")
          row.with_cell(text: "Name and NHS number")
          row.with_cell(text: "Date of birth")
          row.with_cell(text: "Postcode")
          row.with_cell(text: "Year group")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          body.with_row do |row|
            row.with_cell { (changeset.row_number + 2).to_s }

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
                  "Date of birth",
                  class: "nhsuk-table-responsive__heading"
                )
              dob = changeset.date_of_birth.to_date&.to_fs(:long)
              helpers.safe_join([heading, tag.span(dob)])
            end

            row.with_cell do
              heading =
                tag.span("Postcode", class: "nhsuk-table-responsive__heading")
              postcode = changeset.address_postcode
              helpers.safe_join([heading, tag.span(postcode)])
            end

            row.with_cell do
              heading =
                tag.span("Year group", class: "nhsuk-table-responsive__heading")
              year_group =
                changeset.birth_academic_year.to_year_group(academic_year: 2025)
              formatted_year = helpers.format_year_group(year_group)
              helpers.safe_join([heading, tag.span(formatted_year)])
            end
          end
        end
      end
    end
  end
end
