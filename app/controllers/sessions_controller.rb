# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session, except: %i[index planned completed create]

  def create
    skip_policy_scope

    team = current_user.team

    @session =
      Session.create!(
        academic_year: Date.current.academic_year,
        team:,
        programmes: team.programmes
      )

    redirect_to session_edit_path(@session, :location)
  end

  def index
    @sessions = policy_scope(Session).today

    render layout: "full"
  end

  def planned
    @sessions = policy_scope(Session).planned

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
        :triage,
        :vaccination_records
      )

    @counts =
      SessionStats.new(patient_sessions: @patient_sessions, session: @session)

    render layout: "full"
  end

  def edit
  end

  def make_in_progress
    @session.update!(date: Time.zone.today)
    redirect_to session_path,
                flash: {
                  success: {
                    heading: "Session is now in progress"
                  }
                }
  end

  private

  def set_session
    @session = policy_scope(Session).find(params[:id])
  end
end
