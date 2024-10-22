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
    sessions_for_programme =
      policy_scope(Session)
        .has_programme(@programme)
        .includes(:dates, :location)
        .strict_loading

    @scheduled_sessions = sessions_for_programme.scheduled.sort
    @unscheduled_sessions = sessions_for_programme.unscheduled.sort
    @completed_sessions = sessions_for_programme.completed.sort
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:id])
  end
end
