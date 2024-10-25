# frozen_string_literal: true

class AppSessionPatientTableComponent < ViewComponent::Base
  def initialize(
    section:,
    patients: nil,
    patient_sessions: nil,
    caption: nil,
    columns: %i[name year_group],
    consent_form: nil,
    params: {},
    year_groups: []
  )
    super

    if patient_sessions && !patients
      @patients = patient_sessions.map(&:patient)
      @patient_sessions = patient_sessions.map { [_1.patient, _1] }.to_h
    elsif patients && !patient_sessions
      @patients = patients
      @patient_sessions = {}
    else
      raise "Provide only patients or patient sessions."
    end

    @caption = caption
    @columns = columns
    @consent_form = consent_form
    @params = params
    @section = section
    @year_groups = year_groups
  end

  private

  attr_reader :params, :year_groups

  def column_name(column)
    {
      action: "Action needed",
      name: "Full name",
      outcome: "Outcome",
      postcode: "Postcode",
      reason: "Reason for refusal",
      select_for_matching: "Action",
      year_group: "Year group"
    }[
      column
    ]
  end

  def column_value(patient, column)
    patient_session = @patient_sessions[patient]

    case column
    when :action, :outcome
      t("patient_session_statuses.#{patient_session.state}.text")
    when :name
      name_cell(patient)
    when :year_group
      helpers.patient_year_group(patient)
    when :reason
      patient_session
        .consents
        .map { |c| c.human_enum_name(:reason_for_refusal) }
        .uniq
        .join("<br />")
        .html_safe
    when :postcode
      patient.restricted? ? "" : patient.address_postcode
    when :select_for_matching
      matching_link(patient)
    else
      raise ArgumentError, "Unknown column: #{column}"
    end
  end

  def name_cell(patient)
    safe_join(
      [
        patient_link(patient),
        (
          if patient.common_name.present?
            "<span class=\"nhsuk-u-font-size-16\">Known as: ".html_safe +
              patient.common_name + "</span>".html_safe
          end
        )
      ].compact,
      tag.br
    )
  end

  def patient_link(patient)
    session = @patient_sessions[patient]&.session

    if @section == :matching || session.nil?
      patient.full_name
    else
      govuk_link_to patient.full_name,
                    session_patient_path(
                      session,
                      patient,
                      section: params[:section],
                      tab: params[:tab]
                    )
    end
  end

  def matching_link(patient)
    patient_session = @patient_sessions[patient]

    govuk_button_link_to(
      "Select",
      review_match_consent_form_path(
        @consent_form.id,
        patient_session_id: patient_session.id
      ),
      secondary: true,
      class: "app-button--small"
    )
  end

  def header_link(column)
    case @section
    when :matching
      column_name(column)
    else
      direction =
        if params[:sort] == column.to_s && params[:direction] == "asc"
          "desc"
        else
          "asc"
        end
      data = { turbo: "true", turbo_action: "replace" }
      link_to column_name(column),
              session_section_tab_path(
                direction:,
                name: params[:name],
                postcode: params[:postcode],
                section: params[:section],
                session_id: params[:session_id],
                sort: column,
                tab: params[:tab],
                year_groups: params[:year_groups]
              ),
              data:
    end
  end

  def form_url
    session_section_tab_path(
      session_id: params[:session_id],
      section: params[:section],
      tab: params[:tab]
    )
  end

  def header_attributes(column)
    sort =
      if params[:sort] == column.to_s
        params[:direction] == "asc" ? "ascending" : "descending"
      else
        "none"
      end
    { html_attributes: { aria: { sort: } } }
  end
end
