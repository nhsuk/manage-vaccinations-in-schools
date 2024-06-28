# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  attr_reader :params

  def initialize(
    patient_sessions:,
    section:,
    caption: nil,
    columns: %i[name dob],
    consent_form: nil,
    params: {}
  )
    super

    @patient_sessions = patient_sessions
    @columns = columns
    @section = section
    @caption = caption
    @consent_form = consent_form
    @params = params
  end

  private

  def column_name(column)
    {
      action: "Action needed",
      name: "Full name",
      dob: "Date of birth",
      reason: "Reason for refusal",
      outcome: "Outcome",
      postcode: "Postcode",
      select_for_matching: "Action"
    }[
      column
    ]
  end

  def column_value(patient_session, column)
    case column
    when :action, :outcome
      { text: t("patient_session_statuses.#{patient_session.state}.text") }
    when :name
      { text: name_cell(patient_session) }
    when :dob
      {
        text: patient_session.patient.date_of_birth.to_fs(:long),
        html_attributes: {
          "data-filter": patient_session.patient.date_of_birth.to_fs(:uk_short),
          "data-sort": patient_session.patient.date_of_birth
        }
      }
    when :reason
      {
        text:
          patient_session
            .consents
            .map { |c| c.human_enum_name(:reason_for_refusal) }
            .uniq
            .join("<br />")
            .html_safe
      }
    when :postcode
      { text: patient_session.patient.address_postcode }
    when :select_for_matching
      { text: matching_link(patient_session) }
    else
      raise ArgumentError, "Unknown column: #{column}"
    end
  end

  def name_cell(patient_session)
    safe_join(
      [
        patient_link(patient_session),
        (
          if patient_session.patient.common_name.present?
            "<span class=\"nhsuk-u-font-size-16\">Known as: ".html_safe +
              patient_session.patient.common_name + "</span>".html_safe
          end
        )
      ].compact,
      tag.br
    )
  end

  def patient_link(patient_session)
    case @section
    when :matching
      patient_session.patient.full_name
    else
      govuk_link_to patient_session.patient.full_name,
                    session_patient_path(
                      patient_session.session,
                      patient_session.patient,
                      section: params[:section],
                      tab: params[:tab]
                    )
    end
  end

  def matching_link(patient_session)
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
                session_id: params[:session_id],
                section: params[:section],
                tab: params[:tab],
                sort: column,
                direction:,
                name: params[:name],
                dob: params[:dob]
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
