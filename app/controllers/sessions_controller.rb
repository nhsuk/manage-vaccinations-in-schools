# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session, except: %i[index create]

  def create
    skip_policy_scope

    campaign = current_user.team.campaigns.first

    @session = Session.create!(active: false, campaign:)

    redirect_to session_edit_path(@session, :location)
  end

  def index
    @sessions_by_type =
      policy_scope(Session).active.in_progress.group_by(&:type)

    render layout: "full"
  end

  def show
    @patient_sessions =
      @session.patient_sessions.strict_loading.includes(
        :campaign,
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
