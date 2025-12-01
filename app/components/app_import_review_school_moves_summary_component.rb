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
          row.with_cell(text: "CSV file row")
          row.with_cell(text: "Name and NHS number")
          row.with_cell(text: "School move")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          patient = Patient.find(changeset.patient_id)

          body.with_row do |row|
            row.with_cell do
              changeset.row_number ? changeset.csv_row_number.to_s : ""
            end

            row.with_cell do
              helpers.safe_join(
                [
                  tag.span(
                    "Name and NHS number",
                    class: "nhsuk-table-responsive__heading"
                  ),
                  tag.span(patient.full_name),
                  tag.br,
                  tag.span(
                    helpers.patient_nhs_number(patient),
                    class: "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
                  )
                ]
              )
            end

            destination_school_id =
              changeset.review_data.dig("school_move", "school_id")
            home_educated =
              changeset.review_data.dig("school_move", "home_educated")

            destination_school_name =
              if destination_school_id.present?
                destination_school = Location.find(destination_school_id)
                destination_school&.name
              elsif home_educated
                "Home educated"
              else
                "Unknown school"
              end

            school_move_across_teams =
              destination_school && patient.school &&
                (destination_school.teams & patient.school.teams).empty?

            row.with_cell do
              helpers.safe_join(
                [
                  tag.span("Move", class: "nhsuk-table-responsive__heading"),
                  tag.span do
                    helpers.safe_join(
                      [
                        helpers.patient_school(patient),
                        tag.br,
                        tag.span(
                          "to",
                          class:
                            "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
                        ),
                        " ",
                        destination_school_name
                      ]
                    )
                  end,
                  (
                    if school_move_across_teams
                      tag.div(class: "nhsuk-u-margin-top-1") do
                        render(
                          AppStatusComponent.new(
                            text:
                              "This child is moving in from #{patient.school.teams.first.name}'s area",
                            small: true,
                            classes:
                              "nhsuk-u-margin-top-1 nhsuk-u-margin-bottom-0"
                          )
                        )
                      end
                    end
                  )
                ]
              )
            end
          end
        end
      end
    end
  end
end
