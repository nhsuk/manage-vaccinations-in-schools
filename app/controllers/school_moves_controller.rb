# frozen_string_literal: true

class SchoolMovesController < ApplicationController
  before_action :set_session
  before_action :set_location
  before_action :set_tab

  layout "full"

  def index
    @school_moves =
      if @tab == :in
        @location.school_moves_to_this_location
      elsif @tab == :out
        @location.school_moves_from_this_location
      else
        render "errors/not_found", status: :not_found
      end
  end

  def update
    @school_move = policy_scope(SchoolMove).find(params[:id])

    if params[:confirm]
      @school_move.confirm!
    elsif params[:ignore]
      @school_move.ignore!
    else
      render "errors/not_found", status: :not_found
    end

    name = @school_move.patient.full_name
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

  def set_location
    @location = @session.location
  end

  def set_tab
    @tab = params.key?(:in) ? :in : :out
  end
end
