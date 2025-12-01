# frozen_string_literal: true

class AppImportReviewSchoolMovesSummaryComponent < ViewComponent::Base
  def initialize(records:, review_screen: true)
    @records = records
    @review_screen = review_screen
  end

  def call
    helpers.govuk_table(
      html_attributes: {
        class: "nhsuk-table-responsive"
      }
    ) do |table|
      table.with_head do |head|
        head.with_row do |row|
          row.with_cell(text: "CSV file row") if @review_screen
          row.with_cell(text: "Name and NHS number")
          row.with_cell(text: "School move")
          row.with_cell(text: "Actions") unless @review_screen
        end
      end

      table.with_body do |body|
        @records.each do |record|
          patient = (record.is_a?(PatientChangeset) ? record.patient : record)

          body.with_row do |row|
            if @review_screen
              row.with_cell do
                record.row_number ? (record.row_number + 2).to_s : ""
              end
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

            destination_school, destination_school_name =
              destination_school_and_name(record)

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
                    if school_move_across_teams(patient, destination_school)
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

            unless @review_screen
              school_move =
                record
                  .school_moves
                  .where(school_id: destination_school&.id)
                  .order(created_at: :desc)
                  .first
              row.with_cell do
                tag.span("Actions", class: "nhsuk-table-responsive__heading")
                link_to "Review", school_move_path(school_move)
              end
            end
          end
        end
      end
    end
  end

  def destination_school_and_name(record)
    if record.is_a?(PatientChangeset)
      school_id = record.review_data.dig("school_move", "school_id")
      school = school_id.nil? ? nil : Location.find(school_id)
    else
      school = record.school_moves.last.school
    end
    [school, school_name(school, record)]
  end

  def school_name(school, record)
    if school
      school.name
    elsif home_educated(record)
      "Home educated"
    else
      "Unknown school"
    end
  end

  def home_educated(record)
    if record.is_a?(PatientChangeset)
      record.review_data.dig("school_move", "home_educated")
    else
      record.school_moves.last&.home_educated
    end
  end

  def school_move_across_teams(patient, destination_school)
    destination_school && patient.school &&
      (destination_school.teams & patient.school.teams).empty?
  end
end
