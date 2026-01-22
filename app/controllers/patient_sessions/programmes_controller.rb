# frozen_string_literal: true

class PatientSessions::ProgrammesController < PatientSessions::BaseController
  before_action :record_access_log_entry, only: :show

  def show
    render layout: "full"
  end

  def record_already_vaccinated
    authorize VaccinationRecord.new(
                patient: @patient,
                session: @session,
                programme: @programme
              )

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    draft_vaccination_record.clear_attributes
    draft_vaccination_record.update!(
      dose_sequence: @programme.mmr? ? 1 : nil,
      first_active_wizard_step: :confirm,
      location_id: nil,
      location_name: "Unknown",
      outcome: :already_had,
      patient: @patient,
      performed_at: Time.current,
      performed_by_user_id: current_user.id,
      performed_ods_code: current_team.organisation.ods_code,
      programme: @programme,
      session: @session,
      source: "service",
    )

    redirect_to draft_vaccination_record_path("mmr-or-mmrv")
  end

  private

  def access_log_entry_action = :show
end
