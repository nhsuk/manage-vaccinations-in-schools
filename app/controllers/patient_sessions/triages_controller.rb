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
        .find_or_initialize_by(programme: @programme)

    @triage_form =
      TriageForm.new(
        current_user:,
        patient: @patient,
        session: @session,
        programme: @programme,
        triage: previous_triage
      )
  end

  def create
    authorize Triage

    @triage_form =
      TriageForm.new(
        current_user:,
        patient: @patient,
        session: @session,
        programme: @programme,
        **triage_form_params
      )

    if (triage = @triage_form.save)
      StatusUpdater.call(patient: @patient)

      ConsentGrouper
        .call(
          @patient.reload.consents,
          programme_id: @programme.id,
          academic_year: @academic_year
        )
        .each do
          send_triage_confirmation(@patient, @session, @programme, it, triage)
        end

      redirect_to redirect_path, flash: { success: "Triage outcome updated" }
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def triage_form_params
    params.expect(
      triage_form: %i[
        status_option
        notes
        add_patient_specific_direction
        delay_vaccination_until(3i)
        delay_vaccination_until(2i)
        delay_vaccination_until(1i)
      ]
    )
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
