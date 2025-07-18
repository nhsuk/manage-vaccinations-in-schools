# frozen_string_literal: true

class PatientSessions::TriagesController < PatientSessions::BaseController
  include TriageMailerConcern

  after_action :verify_authorized

  def new
    authorize Triage

    previous_triage =
      @patient
        .triages
        .not_invalidated
        .order(created_at: :desc)
        .find_by(programme: @programme)

    @triage_form =
      TriageForm.new(
        patient_session: @patient_session,
        programme: @programme,
        triage: previous_triage
      )
  end

  def create
    authorize Triage

    @triage_form =
      TriageForm.new(
        current_user:,
        patient_session: @patient_session,
        programme: @programme,
        **triage_form_params
      )

    if @triage_form.save
      StatusUpdater.call(patient: @patient)

      ConsentGrouper
        .call(@patient.reload.consents, programme: @programme)
        .each { send_triage_confirmation(@patient_session, it) }

      redirect_to redirect_path, flash: { success: "Triage outcome updated" }
    else
      render "patient_sessions/programmes/show",
             layout: "full",
             status: :unprocessable_entity
    end
  end

  private

  def triage_form_params
    params.expect(triage_form: %i[status_and_vaccine_method notes])
  end

  def redirect_path
    session_patient_programme_path(
      @session,
      @patient,
      @programme,
      return_to: "triage"
    )
  end
end
