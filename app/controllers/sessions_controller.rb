# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session, only: %i[show edit make_in_progress]

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

  def closed
    @sessions = sessions_scope.closed.sort

    render layout: "full"
  end

  def show
    @patient_sessions =
      @session.patient_sessions.strict_loading.includes(
        :programmes,
        :triages,
        :vaccination_records,
        :latest_gillick_assessment,
        :latest_vaccination_record,
        consents: :parent
      )

    @counts =
      SessionStats.new(patient_sessions: @patient_sessions, session: @session)

    render layout: "full"
  end

  def edit
  end

  def make_in_progress
    @session.dates.find_or_create_by!(value: Date.current)

    redirect_to session_path,
                flash: {
                  success: {
                    heading: "Session is now in progress"
                  }
                }
  end

  private

  delegate :team, to: :current_user

  def academic_year
    Date.current.academic_year
  end

  def set_session
    @session =
      policy_scope(Session).includes(
        :team,
        :location,
        :dates,
        :programmes
      ).find(params[:id])
  end

  def sessions_scope
    policy_scope(Session).includes(
      :dates,
      :location,
      :programmes
    ).strict_loading
  end
end
