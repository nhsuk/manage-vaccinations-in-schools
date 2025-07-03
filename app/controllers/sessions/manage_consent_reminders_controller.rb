# frozen_string_literal: true

class Sessions::ManageConsentRemindersController < ApplicationController
  before_action :set_session

  def create
    SendManualSchoolConsentRemindersJob.perform_now(@session, current_user:)

    redirect_to session_path(@session),
                flash: {
                  success: "Manual consent reminders sent."
                }
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
