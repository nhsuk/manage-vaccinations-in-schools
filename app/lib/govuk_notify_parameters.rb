# frozen_string_literal: true

class GovukNotifyParameters
  def initialize(
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    patient_session: nil,
    programme: nil,
    session: nil,
    vaccination_record: nil
  )
    patient_session ||= vaccination_record&.patient_session

    @consent = consent
    @consent_form = consent_form
    @parent = parent || consent&.parent
    @patient = patient || consent&.patient || patient_session&.patient
    @programme =
      programme || vaccination_record&.programme || consent_form&.programme ||
        consent&.programme
    @session =
      session || consent_form&.actual_upcoming_session ||
        consent_form&.original_session || patient_session&.session
    @organisation =
      session&.organisation || patient_session&.organisation ||
        consent_form&.organisation || consent&.organisation ||
        vaccination_record&.organisation
    @team =
      session&.team || patient_session&.team || consent_form&.team ||
        vaccination_record&.team
    @vaccination_record = vaccination_record
  end

  attr_reader :consent,
              :consent_form,
              :parent,
              :patient,
              :programme,
              :session,
              :team,
              :organisation,
              :vaccination_record
end
