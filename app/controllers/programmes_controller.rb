# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: %i[index create]

  skip_after_action :verify_policy_scoped, only: :create

  layout "full"

  def index
    @programmes = programmes
  end

  def create
    programme = Programme.create!(team: current_user.team)
    redirect_to programme_edit_path(programme, Wicked::FIRST_STEP)
  end

  def show
  end

  def patients
    @patients = @programme.patients.active
  end

  def sessions
    @in_progress_sessions = @programme.sessions.active.in_progress
    @future_sessions = @programme.sessions.active.future
    @past_sessions = @programme.sessions.active.past
  end

  private

  def programmes
    @programmes ||= policy_scope(Programme).active
  end

  def set_programme
    @programme = programmes.find(params[:id])
  end
end
