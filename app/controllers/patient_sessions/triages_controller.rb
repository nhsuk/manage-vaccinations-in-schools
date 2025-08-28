# frozen_string_literal: true

class PatientSessions::TriagesController < PatientSessions::BaseController
  include TriageMailerConcern

  after_action :verify_authorized

  def new
    authorize Triage

    previous_triage =
      @patient
        .triages
        .where(academic_year: @session.academic_year)
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
        .call(
          @patient.reload.consents,
          programme_id: @programme.id,
          academic_year: @academic_year
        )
        .each { send_triage_confirmation(@patient_session, @programme, it) }

      ensure_psd_exists if @triage_form.add_psd?

      redirect_to redirect_path, flash: { success: "Triage outcome updated" }
    else
      render "patient_sessions/programmes/show",
             layout: "full",
             status: :unprocessable_content
    end
  end

  private

  def triage_form_params
    params.expect(triage_form: %i[status_and_vaccine_method notes add_psd])
  end

  def redirect_path
    session_patient_programme_path(
      @session,
      @patient,
      @programme,
      return_to: "triage"
    )
  end

  def ensure_psd_exists
    psd_attributes = {
      academic_year: @academic_year,
      delivery_site: "nose",
      patient: @patient,
      programme: @programme,
      vaccine: @programme.vaccines.nasal.first,
      vaccine_method: "nasal"
    }

    return if PatientSpecificDirection.exists?(**psd_attributes)

    PatientSpecificDirection.create!(
      psd_attributes.merge(created_by: current_user)
    )
  end
end
