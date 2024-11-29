# frozen_string_literal: true

class SchoolMovesController < ApplicationController
  include Pagy::Backend

  layout "full"

  def index
    @pagy, @school_moves = pagy(policy_scope(SchoolMove).order(:updated_at))
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
        { success: "#{name}’s record updated with new school" }
      else
        { notice: "#{name}’s school move ignored" }
      end

    redirect_to school_moves_path, flash:
  end
end
