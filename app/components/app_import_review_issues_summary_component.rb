# frozen_string_literal: true

class AppImportReviewIssuesSummaryComponent < ViewComponent::Base
  def initialize(import: nil, records: nil, review_screen: true)
    @import = import
    @records = Array(records).sort_by { it.try(:row_number) || 0 }
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
          row.with_cell(text: "Issue to review")
          row.with_cell(text: "Actions") unless @review_screen
        end
      end
      table.with_body do |body|
        @records.each do |record|
          body.with_row do |row|
            row.with_cell { record.csv_row_number.to_s } if @review_screen
            row.with_cell { render_name_cell(record) }
            row.with_cell { render_issue_cell(record) }
            row.with_cell { render_action_cell(record) } unless @review_screen
          end
        end
      end
    end
  end

  private

  def render_name_cell(record)
    heading =
      tag.span("Name and NHS number", class: "nhsuk-table-responsive__heading")
    name = format_name(record)
    nhs_number = format_nhs_number(record)

    helpers.safe_join(
      [
        heading,
        tag.span(name),
        tag.br,
        tag.span(
          nhs_number,
          class: "nhsuk-u-secondary-text-colour nhsuk-u-font-size-16"
        )
      ]
    )
  end

  def render_issue_cell(record)
    heading =
      tag.span("Issue to review", class: "nhsuk-table-responsive__heading")
    issue_text = determine_issue_text(record)
    helpers.safe_join([heading, tag.span(issue_text)])
  end

  def render_action_cell(record)
    heading = tag.span("Actions", class: "nhsuk-table-responsive__heading")
    action_link = generate_action_link(record)
    helpers.safe_join([heading, action_link])
  end

  def format_name(record)
    case record
    when PatientChangeset
      FullNameFormatter.call(record, context: :internal)
    when Patient
      record.full_name
    when VaccinationRecord
      record.patient&.full_name || "Unknown"
    else
      raise "Unknown record type: #{record.class.name}"
    end
  end

  def format_nhs_number(record)
    case record
    when PatientChangeset
      helpers.format_nhs_number(record.nhs_number)
    when Patient
      helpers.format_nhs_number(record.nhs_number)
    when VaccinationRecord
      helpers.format_nhs_number(record.patient&.nhs_number)
    else
      raise "Unknown record type: #{record.class.name}"
    end
  end

  def determine_issue_text(record)
    case record
    when PatientChangeset, Patient
      patient_import_issue_text(record)
    when VaccinationRecord
      "Imported record closely matches an existing record. Review and confirm."
    else
      raise "Unknown record type: #{record.class.name}"
    end
  end

  def patient_import_issue_text(record)
    pending_changes =
      if record.is_a?(PatientChangeset)
        record.review_data["patient"]["pending_changes"] || {}
      else
        record.pending_changes || {}
      end
    issue_groups = helpers.issue_categories_for(pending_changes.keys)

    if issue_groups.any? && matched_on_nhs_number?(record)
      "Matched on NHS number. " \
        "#{issue_groups.to_sentence.capitalize} #{issue_groups.size == 1 ? "does not" : "do not"} match."
    else
      "Possible match found. Review and confirm."
    end
  end

  def matched_on_nhs_number?(record)
    if record.is_a?(PatientChangeset)
      record.matched_on_nhs_number?
    elsif record.is_a?(Patient)
      @import
        &.changesets
        &.find_by(patient_id: record.id)
        &.matched_on_nhs_number?
    end
  end

  def generate_action_link(record)
    case record
    when Patient
      helpers.link_to(imports_issue_path(record, type: "patient")) do
        helpers.safe_join(
          [
            "Review ",
            tag.span(record.full_name, class: "nhsuk-u-visually-hidden")
          ]
        )
      end
    when VaccinationRecord
      helpers.link_to(imports_issue_path(record, type: "vaccination-record")) do
        helpers.safe_join(
          [
            "Review ",
            tag.span(
              record.patient&.full_name,
              class: "nhsuk-u-visually-hidden"
            )
          ]
        )
      end
    else
      ""
    end
  end
end
