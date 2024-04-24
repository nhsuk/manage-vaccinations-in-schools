class AppPatientTableComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :filter_actions

  def initialize(
    patient_sessions:,
    tab_id: nil,
    caption: nil,
    columns: %i[name dob],
    route: nil,
    consent_form: nil,
    filter_actions: false
  )
    super

    @patient_sessions = patient_sessions
    @columns = columns
    @route = route
    @tab_id = tab_id
    @caption = caption
    @consent_form = consent_form
    @filter_actions = filter_actions
  end

  private

  def column_name(column)
    {
      action: "Action needed",
      name: "Name",
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
      {
        text:
          govuk_tag(
            classes: "nhsuk-u-font-size-16 nhsuk-u-width-full",
            text: t("patient_session_statuses.#{patient_session.state}.text"),
            colour:
              t("patient_session_statuses.#{patient_session.state}.colour")
          )
      }
    when :name
      { text: name_cell(patient_session) }
    when :dob
      {
        text:
          patient_session.patient.date_of_birth.to_fs(:nhsuk_date_short_month),
        html_attributes: {
          "data-filter":
            patient_session.patient.date_of_birth.strftime("%d/%m/%Y"),
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
    case @route
    when :consent
      govuk_link_to patient_session.patient.full_name,
                    session_patient_consents_path(
                      patient_session.session,
                      patient_session.patient
                    )
    when :triage
      govuk_link_to patient_session.patient.full_name,
                    session_patient_triage_path(
                      patient_session.session,
                      patient_session.patient
                    )
    when :vaccination
      govuk_link_to patient_session.patient.full_name,
                    session_patient_vaccinations_path(
                      patient_session.session,
                      patient_session.patient
                    )
    when :matching
      patient_session.patient.full_name
    else
      raise ArgumentError, "Unknown route: #{@route}"
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
end
