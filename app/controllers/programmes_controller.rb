# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = programmes
  end

  def show
  end

  def sessions
    academic_year = Date.current.academic_year

    @scheduled_sessions = @programme.sessions.scheduled

    @unscheduled_sessions =
      @programme.sessions.unscheduled +
        Location
          .school
          .for_programme(@programme)
          .has_no_session(academic_year)
          .map do |location|
            Session.new(team: @programme.team, location:, academic_year:)
          end

    @completed_sessions = @programme.sessions.completed
  end

  private

  def programmes
    @programmes ||= policy_scope(Programme)
  end

  def set_programme
    @programme = programmes.find(params[:id])
  end
end
