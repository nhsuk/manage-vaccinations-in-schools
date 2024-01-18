class AppPatientTableComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(patient_sessions:, tab_id:, columns: %i[name dob], route: nil)
    super

    @patient_sessions = patient_sessions
    @columns = columns
    @route = route
    @tab_id = tab_id
  end

  private

  def column_name(column)
    { name: "Name", dob: "Date of birth", reason: "Reason for refusal" }[column]
  end

  def column_value(patient_session, column)
    case column
    when :name
      { text: patient_link(patient_session) }
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
    else
      raise ArgumentError, "Unknown column: #{column}"
    end
  end

  def patient_link(patient_session)
    if @route == :consent
      govuk_link_to patient_session.patient.full_name,
                    session_patient_consents_path(
                      patient_session.session,
                      patient_session.patient
                    )
    elsif @route == :triage
      govuk_link_to patient_session.patient.full_name,
                    session_patient_triage_path(
                      patient_session.session,
                      patient_session.patient
                    )
    else
      raise ArgumentError, "Unknown route: #{@route}"
    end
  end
end
