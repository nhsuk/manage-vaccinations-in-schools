class ConsentFormsController < ApplicationController
  def unmatched_responses
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
    @unmatched_consent_responses =
      @session.consent_forms.unmatched.recorded.order(:recorded_at)
  end

  def show
    @consent_form = policy_scope(ConsentForm).find(params[:id])
    @patient_sessions =
      @consent_form
        .session
        .patient_sessions
        .includes(:patient)
        .order("patients.last_name")
  end

  def review_match
    @consent_form = policy_scope(ConsentForm).find(params[:id])
    @patient_session =
      policy_scope(PatientSession).find(params[:patient_session_id])
  end

  def match
    @consent_form = policy_scope(ConsentForm).find(params[:id])
    @patient_session =
      policy_scope(PatientSession).find(params[:patient_session_id])

    Consent.from_consent_form!(@consent_form, @patient_session)

    session = @consent_form.session

    success_flash_after_patient_update(
      patient: @patient_session.patient,
      view_record_link:
        session_patient_triage_path(session, @patient_session.patient)
    )

    @unmatched_consent_responses =
      session.consent_forms.unmatched.recorded.order(:recorded_at)

    if @unmatched_consent_responses.any?
      redirect_to unmatched_responses_session_path(@consent_form.session.id)
    else
      redirect_to consents_session_path(session)
    end
  end
end
