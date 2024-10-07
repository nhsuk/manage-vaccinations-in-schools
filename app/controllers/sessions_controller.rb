# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :set_session,
                except: %i[new index scheduled unscheduled completed]

  skip_after_action :verify_policy_scoped, only: :new

  def new
    location =
      team.schools.for_year_groups(team.year_groups).find(params[:location_id])

    session =
      ActiveRecord::Base.transaction do
        Session.find_or_create_by!(team:, location:, academic_year:).tap(
          &:create_patient_sessions!
        )
      end

    redirect_to session_path(session)
  end

  def index
    @sessions = policy_scope(Session).today

    render layout: "full"
  end

  def scheduled
    @sessions = policy_scope(Session).scheduled

    render layout: "full"
  end

  def unscheduled
    @sessions =
      policy_scope(Session).unscheduled +
        team
          .schools
          .for_year_groups(team.year_groups)
          .has_no_session
          .map { |location| Session.new(team:, location:, academic_year:) }

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
    @session.update!(date: Time.zone.today)
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
