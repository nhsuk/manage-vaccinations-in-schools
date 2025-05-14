# frozen_string_literal: true

class PatientSessions::ProgrammesController < PatientSessions::BaseController
  before_action :record_access_log_entry, only: :show

  def show
    render layout: "full"
  end

  def record_already_vaccinated
    unless @patient_session.can_record_as_already_vaccinated?(
             programme: @programme
           )
      redirect_to session_patient_path and return
    end

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    draft_vaccination_record.clear_attributes
    draft_vaccination_record.update!(
      first_active_wizard_step: :confirm,
      location: nil,
      location_name: "Unknown",
      outcome: :already_had,
      patient: @patient,
      performed_at: Time.current,
      performed_by_user_id: current_user.id,
      performed_ods_code: current_team.organisation.ods_code,
      programme: @programme,
      session: @session
    )

    redirect_to draft_vaccination_record_path("confirm")
  end

  private

  def access_log_entry_action = :show
end
