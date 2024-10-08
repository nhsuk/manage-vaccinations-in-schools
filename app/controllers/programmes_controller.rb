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
    sessions_for_programme = policy_scope(Session).has_programme(@programme)

    @scheduled_sessions = sessions_for_programme.scheduled
    @unscheduled_sessions = sessions_for_programme.unscheduled
    @completed_sessions = sessions_for_programme.completed
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find(params[:id])
  end
end
