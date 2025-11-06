# frozen_string_literal: true

class AppImportReviewSchoolMovesSummaryComponent < ViewComponent::Base
  def initialize(changesets:)
    @changesets = changesets
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
          row.with_cell(text: "School move")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          patient = Patient.find(changeset.patient_id)

          body.with_row do |row|
            row.with_cell do
              helpers.safe_join(
                [
                  helpers.content_tag(
                    :span,
                    "Name and NHS number",
                    class: "nhsuk-table-responsive__heading"
                  ),
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

            destination_school =
              changeset.review_data.dig("school_move", "school_id")
            home_educated =
              changeset.review_data.dig("school_move", "home_educated")

            destination_school_name =
              if destination_school.present?
                Location.find_by(id: destination_school)&.name
              elsif home_educated
                "Home educated"
              else
                "Unknown school"
              end

            row.with_cell do
              helpers.safe_join(
                [
                  helpers.content_tag(
                    :span,
                    "Move",
                    class: "nhsuk-table-responsive__heading"
                  ),
                  helpers.content_tag(:span) do
                    helpers.safe_join(
                      [
                        helpers.patient_school(patient),
                        helpers.tag.br,
                        helpers.content_tag(
                          :span,
                          "to",
                          class:
                            "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
                        ),
                        helpers.tag.br,
                        destination_school_name
                      ]
                    )
                  end
                ]
              )
            end
          end
        end
      end
    end
  end
end
