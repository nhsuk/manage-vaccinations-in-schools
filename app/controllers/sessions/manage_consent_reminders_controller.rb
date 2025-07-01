# frozen_string_literal: true

class Sessions::ManageConsentRemindersController < ApplicationController
  before_action :set_session

  def show
    authorize :consent_reminder, :show?
  end

  def create
    authorize :consent_reminder, :create?
    SendSchoolConsentRemindersJob.perform_now(@session)

    redirect_to session_path(@session),
                flash: {
                  success: "Manual consent reminders sent."
                }
  end

  private

  def set_session
    @session = authorize sessions_scope.find_by!(slug: params[:session_slug])
  end

  def sessions_scope
    policy_scope(Session).includes(:location, :programmes, :session_dates)
  end
end
