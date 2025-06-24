# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session, except: %i[index scheduled unscheduled completed]

  def index
    @sessions = sessions_scope.today.sort

    render layout: "full"
  end

  def scheduled
    @sessions = sessions_scope.scheduled.sort

    render layout: "full"
  end

  def unscheduled
    @sessions = sessions_scope.unscheduled.sort

    render layout: "full"
  end

  def completed
    @sessions = sessions_scope.completed.sort

    render layout: "full"
  end

  def show
    respond_to do |format|
      format.html { render layout: "full" }

      format.xlsx do
        filename =
          if @session.location.urn.present?
            "#{@session.location.name} (#{@session.location.urn})"
          else
            @session.location.name
          end

        send_data(
          Reports::OfflineSessionExporter.call(@session),
          filename:
            "#{filename} - exported on #{Date.current.to_fs(:long)}.xlsx",
          disposition: "attachment"
        )
      end
    end
  end

  def edit
  end

  def make_in_progress
    @session.session_dates.find_or_create_by!(value: Date.current)

    redirect_to layout: "full", flash: { success: "Session is now in progress" }
  end

  def send_extra_consent_reminders
    SendSchoolConsentRemindersJob.perform_now(@session)

    redirect_to edit_session_path(@session), flash: { success: "Consent reminders sent." }
  end

  private

  def set_session
    @session = authorize sessions_scope.find_by!(slug: params[:slug])
  end

  def sessions_scope
    policy_scope(Session).includes(:location, :programmes, :session_dates)
  end
end
