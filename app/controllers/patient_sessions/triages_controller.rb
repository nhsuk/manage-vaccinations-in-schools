# frozen_string_literal: true

class PatientSessions::TriagesController < PatientSessions::BaseController
  include TriageMailerConcern

  before_action :set_triage

  after_action :verify_authorized

  def new
    authorize @triage
  end

  def create
    @triage.assign_attributes(triage_params.merge(performed_by: current_user))

    authorize @triage

    if @triage.save(context: :consent)
      StatusUpdater.call(patient: @patient)

      ConsentGrouper
        .call(@patient.reload.consents, programme: @programme)
        .each { send_triage_confirmation(@patient_session, it) }

      redirect_to redirect_path, flash: { success: "Triage outcome updated" }
    else
      render "patient_sessions/programmes/show", status: :unprocessable_entity
    end
  end

  private

  def set_triage
    @triage =
      Triage.new(
        patient: @patient,
        programme: @programme,
        organisation: @session.organisation
      )
  end

  def triage_params
    params.expect(triage: %i[status notes])
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
