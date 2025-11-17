# frozen_string_literal: true

class AppImportReviewRecordsSummaryComponent < ViewComponent::Base
  def initialize(changesets:)
    @changesets = changesets.sort_by(&:row_number)
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
          row.with_cell(text: "Date of birth")
          row.with_cell(text: "Postcode")
          row.with_cell(text: "Year group")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          body.with_row do |row|
            patient = changeset.patient

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
                  "Date of birth",
                  class: "nhsuk-table-responsive__heading"
                )
              dob = patient.date_of_birth.to_date&.to_fs(:long)
              helpers.safe_join([heading, helpers.content_tag(:span, dob)])
            end

            row.with_cell do
              heading =
                helpers.content_tag(
                  :span,
                  "Postcode",
                  class: "nhsuk-table-responsive__heading"
                )
              postcode = patient.address_postcode
              helpers.safe_join([heading, helpers.content_tag(:span, postcode)])
            end

            row.with_cell do
              heading =
                helpers.content_tag(
                  :span,
                  "Year group",
                  class: "nhsuk-table-responsive__heading"
                )
              year_group =
                patient.year_group(academic_year: AcademicYear.current)
              formatted_year = helpers.format_year_group(year_group)
              helpers.safe_join(
                [heading, helpers.content_tag(:span, formatted_year)]
              )
            end
          end
        end
      end
    end
  end
end
