# frozen_string_literal: true

class Sessions::ManageConsentRemindersController < Sessions::BaseController
  before_action :authorize_session

  def show
  end

  def create
    SendManualSchoolConsentRemindersJob.perform_now(@session, current_user:)

    redirect_to session_path(@session),
                flash: {
                  success: "Manual consent reminders sent"
                }
  end

  private

  def authorize_session
    authorize @session, :manage_consent_reminders?
  end
end
