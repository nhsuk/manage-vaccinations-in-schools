# frozen_string_literal: true

class PatientSessions::ActivitiesController < PatientSessions::BaseController
  before_action :record_access_log_entry, only: :show

  before_action :set_note

  def show
  end

  def create
    if @note.update(note_params)
      redirect_to session_patient_activity_path(@session, @patient),
                  flash: {
                    success: "Note added"
                  }
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_note
    @note =
      Note.new(created_by: current_user, patient: @patient, session: @session)
  end

  def note_params = params.expect(note: %i[body])

  def access_log_entry_action = "log"
end
