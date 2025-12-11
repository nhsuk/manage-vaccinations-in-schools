# frozen_string_literal: true

class AppImportReviewIssuesSummaryComponent < ViewComponent::Base
  DISPLAYABLE_ATTRIBUTES = {
    "nhs_number" => "NHS number",
    "given_name" => "First name",
    "family_name" => "Last name",
    "preferred_given_name" => "Preferred first name",
    "preferred_family_name" => "Preferred last name",
    "date_of_birth" => "Date of birth",
    "gender_code" => "Gender",
    "address_line_1" => "Address line 1",
    "address_line_2" => "Address line 2",
    "address_town" => "Town",
    "address_postcode" => "Postcode",
    "registration" => "Registration",
    "birth_academic_year" => "Year group"
  }.freeze

  erb_template <<-ERB
    <%= helpers.govuk_table(
      html_attributes: {
        class: "nhsuk-table-responsive app-table--review"
      }
    ) do |table| %>
      <% table.with_head do |head| %>
        <% head.with_row do |row| %>
          <% row.with_cell(text: "CSV file row") if review_screen %>
          <% row.with_cell(text: "Name and NHS number") %>
          <% row.with_cell(text: issue_header_text) %>
          <% if !@review_screen %>
            <% row.with_cell(text: "Actions") %>
          <% elsif Flipper.enabled?(:import_handle_issues_in_review) %>
            <% row.with_cell(text: "Decision") %>
          <% end %>
        <% end %>
      <% end %>
      <% table.with_body do |body| %>
        <% records.each do |record| %>
          <% body.with_row do |row| %>
            <% if review_screen %>
              <% row.with_cell do %>
                <span class="nhsuk-table-responsive__heading">CSV file row</span>
                <span><%= record.csv_row_number.to_s %></span>
              <% end %>
            <% end %>

            <% row.with_cell do %>
              <span class="nhsuk-table-responsive__heading">Name and NHS number</span>
              <span><%= format_name(record) %></span>
              <br>
              <span class="nhsuk-u-secondary-text-colour nhsuk-u-font-size-16">
                <%= format_nhs_number(record) %>
              </span>
            <% end %>

            <% row.with_cell do %>
              <span class="nhsuk-table-responsive__heading">Issue to review</span>
              <span><%= determine_issue_text(record) %></span>
            <% end %>

            <% if !review_screen %>
              <% row.with_cell do %>
                <span class="nhsuk-table-responsive__heading">Actions</span>
                <%= generate_action_link(record) %>
              <% end %>
            <% elsif @form && Flipper.enabled?(:import_handle_issues_in_review) %>
              <% row.with_cell do %>
                <span class="nhsuk-table-responsive__heading">Decision</span>
                <div class="nhsuk-u-margin-bottom-2" data-changeset-id="<%= record.id %>">
                  <%= @form.fields_for :changesets, record do |changeset_fields| %>
                    <%= changeset_fields.govuk_collection_radio_buttons :decision, 
                        available_decision_options(changeset_fields.object), 
                        :option, 
                        :label, 
                        small: true, 
                        legend: { hidden: true }, 
                        required: true %>
                  <% end %>
                </div>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    <% end %>
  ERB

  def initialize(import: nil, records: nil, review_screen: true, form: nil)
    @import = import
    @records = Array(records).sort_by { it.try(:row_number) || 0 }
    @review_screen = review_screen
    @form = form
  end

  private

  attr_reader :import, :records, :review_screen

  def format_name(record)
    case record
    when Patient
      record.full_name
    when VaccinationRecord, PatientChangeset
      record.patient&.full_name || "Unknown"
    else
      raise "Unknown record type: #{record.class.name}"
    end
  end

  def format_nhs_number(record)
    nhs_number =
      case record
      when Patient
        record.nhs_number
      when VaccinationRecord, PatientChangeset
        record.patient&.nhs_number
      else
        raise "Unknown record type: #{record.class.name}"
      end

    helpers.format_nhs_number(nhs_number)
  end

  def issue_header_text
    if Flipper.enabled?(:import_handle_issues_in_review)
      helpers.safe_join(
        [
          "Existing record ",
          arrow,
          tag.mark(" Uploaded record", class: "app-highlight")
        ]
      )
    else
      "Issue to review"
    end
  end

  def determine_issue_text(record)
    case record
    when PatientChangeset
      if Flipper.enabled?(:import_handle_issues_in_review)
        changeset_import_issue_text(record)
      else
        patient_import_issue_text(record)
      end
    when Patient
      patient_import_issue_text(record)
    when VaccinationRecord
      "Imported record closely matches an existing record. Review and confirm."
    else
      raise "Unknown record type: #{record.class.name}"
    end
  end

  def changeset_import_issue_text(changeset)
    pending_changes = changeset.pending_changes || {}
    sorted_changes =
      DISPLAYABLE_ATTRIBUTES.keys.filter_map do |attr|
        [attr, pending_changes[attr]] if pending_changes.key?(attr)
      end
    if sorted_changes.empty?
      raise "No displayable pending changes found for changeset #{changeset.id}"
    end

    patient = changeset.patient

    helpers.govuk_summary_list(
      actions: false,
      html_attributes: {
        style: "table-layout: auto;"
      }
    ) do |summary_list|
      sorted_changes.each do |attribute, new_value|
        summary_list.with_row do |row|
          row.with_key { DISPLAYABLE_ATTRIBUTES[attribute] }
          row.with_value { format_change(patient, attribute, new_value) }
        end
      end
    end
  end

  def format_change(patient, attribute, new_value)
    old_value = format_value(patient.public_send(attribute), attribute)
    new_value_formatted = format_value(new_value, attribute)

    helpers.safe_join(
      [
        old_value,
        " ",
        arrow,
        " ",
        tag.mark(new_value_formatted, class: "app-highlight")
      ]
    )
  end

  def format_value(value, attribute)
    return "Not provided" if value.blank?

    case attribute
    when "date_of_birth", "date_of_death"
      value&.to_date&.to_fs(:long)
    when "nhs_number"
      helpers.format_nhs_number(value)
    when "address_postcode"
      value.upcase
    when "gender_code"
      value&.humanize
    when "registration"
      value.to_s.humanize
    when "birth_academic_year"
      value.to_year_group.to_s
    else
      value.to_s
    end
  end

  def arrow
    arrow_path = <<~PATH.squish
      m14.7 6.3 5 5c.2.2.3.4.3.7 0 .3-.1.5-.3.7l-5 5a1 1 0 0 1-1.4-1.4l3.3-3.3H5a1 1 0 0 1 0-2h11.6l-3.3-3.3a1 1 0 1 1 1.4-1.4Z
    PATH

    tag.svg(
      title: "changed to",
      class: "nhsuk-icon nhsuk-icon--arrow-right",
      xmlns: "http://www.w3.org/2000/svg",
      height: "16",
      width: "16",
      focusable: "false",
      viewBox: "0 0 24 24",
      role: "img",
      aria: {
        label: "changed to"
      }
    ) { tag.path(d: arrow_path) }
  end

  def patient_import_issue_text(record)
    pending_changes = record.pending_changes || {}
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
      import&.changesets&.find_by(patient_id: record.id)&.matched_on_nhs_number?
    end
  end

  def generate_action_link(record)
    case record
    when Patient
      review_link(record, "patient")
    when VaccinationRecord
      review_link(record, "vaccination-record")
    else
      ""
    end
  end

  def review_link(record, type)
    full_name =
      record.is_a?(Patient) ? record.full_name : record.patient&.full_name

    helpers.link_to(imports_issue_path(record, type:)) do
      helpers.safe_join(
        ["Review ", tag.span(full_name, class: "nhsuk-u-visually-hidden")]
      )
    end
  end

  def available_decision_options(changeset)
    duplicate_option = Struct.new(:changeset_id, :label, :option)

    if changeset.matched_on_nhs_number?
      [
        duplicate_option.new(
          changeset_id: changeset.id,
          label: "Use uploaded",
          option: "apply"
        ),
        duplicate_option.new(
          changeset_id: changeset.id,
          label: "Keep existing",
          option: "discard"
        )
      ]
    else
      [
        duplicate_option.new(
          changeset_id: changeset.id,
          label: "Use uploaded",
          option: "apply"
        ),
        duplicate_option.new(
          changeset_id: changeset.id,
          label: "Keep existing",
          option: "discard"
        ),
        duplicate_option.new(
          changeset_id: changeset.id,
          label: "Keep both",
          option: "keep_both"
        )
      ]
    end
  end
end
