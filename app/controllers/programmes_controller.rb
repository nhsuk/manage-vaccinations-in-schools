# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = programmes
  end

  def show
  end

  def patients
    @patients = @programme.patients.recorded
  end

  def sessions
    @in_progress_sessions = @programme.sessions.active.in_progress
    @future_sessions = @programme.sessions.active.future
    @past_sessions = @programme.sessions.active.past
  end

  private

  def programmes
    @programmes ||= policy_scope(Programme)
  end

  def set_programme
    @programme = programmes.find(params[:id])
  end
end
