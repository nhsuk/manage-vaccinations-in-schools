# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session, only: %i[show edit make_in_progress]

  def index
    @sessions = policy_scope(Session).today

    render layout: "full"
  end

  def scheduled
    @sessions = policy_scope(Session).scheduled

    render layout: "full"
  end

  def unscheduled
    @sessions = policy_scope(Session).unscheduled

    render layout: "full"
  end

  def completed
    @sessions = policy_scope(Session).completed

    render layout: "full"
  end

  def show
    @patient_sessions =
      @session.patient_sessions.strict_loading.includes(
        :programmes,
        :gillick_assessment,
        { consents: :parent },
        :latest_triage,
        :vaccination_records,
        :latest_vaccination_record
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
end
