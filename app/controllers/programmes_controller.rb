# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = policy_scope(Programme)
  end

  def show
  end

  def sessions
    academic_year = Date.current.academic_year

    @scheduled_sessions = @programme.sessions.scheduled

    @unscheduled_sessions =
      @programme.sessions.unscheduled.where(academic_year:) +
        policy_scope(Location)
          .school
          .for_year_groups(@programme.year_groups)
          .has_no_session(academic_year)
          .map do |location|
            Session.new(team: current_user.team, location:, academic_year:)
          end

    @completed_sessions = @programme.sessions.completed.where(academic_year:)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:id])
  end
end
