# frozen_string_literal: true

class SessionMovesController < ApplicationController
  before_action :set_session
  before_action :set_tab

  layout "full"

  def index
    @patient_sessions =
      if @tab == :in
        @session.patient_sessions_moving_to_this_session
      elsif @tab == :out
        @session.patient_sessions_moving_from_this_session
      else
        render "errors/not_found", status: :not_found
      end
  end

  def update
    @patient_session = policy_scope(PatientSession).find(params[:id])

    if params[:confirm]
      @patient_session.confirm_transfer!
    elsif params[:ignore]
      @patient_session.ignore_transfer!
    else
      render "errors/not_found", status: :not_found
    end

    name = @patient_session.patient.full_name
    flash =
      if params[:confirm]
        { success: "#{name} moved #{@tab}" }
      else
        { notice: "#{name} move ignored" }
      end

    redirect_to session_moves_path(@session) + "?#{@tab}", flash:
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_tab
    @tab = params.key?(:in) ? :in : :out
  end
end
