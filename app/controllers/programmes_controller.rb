# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = policy_scope(Programme).includes(:active_vaccines)
  end

  def show
  end

  def sessions
    sessions_for_programme =
      policy_scope(Session)
        .has_programme(@programme)
        .includes(:dates, :location)
        .strict_loading

    @closed_sessions = sessions_for_programme.closed.sort
    @completed_sessions = sessions_for_programme.completed.sort
    @scheduled_sessions = sessions_for_programme.scheduled.sort
    @unscheduled_sessions = sessions_for_programme.unscheduled.sort
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:id])
  end
end
