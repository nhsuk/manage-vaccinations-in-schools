# frozen_string_literal: true

class SchoolMovesController < ApplicationController
  include Pagy::Backend

  before_action :set_school_move, except: :index
  before_action :set_patient, except: :index

  layout "full"

  def index
    @pagy, @school_moves = pagy(policy_scope(SchoolMove).order(:updated_at))
  end

  def show
    @form = SchoolMoveForm.new(current_user:, school_move: @school_move)
  end

  def update
    @form =
      SchoolMoveForm.new(
        current_user:,
        school_move: @school_move,
        action: params.dig(:school_move_form, :action)
      )

    if @form.save
      name = @school_move.patient.full_name
      flash =
        if @form.action == "confirm"
          { success: "#{name}’s school record updated" }
        else
          { notice: "#{name}’s school move ignored" }
        end

      redirect_to school_moves_path, flash:
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_school_move
    @school_move = policy_scope(SchoolMove).find(params[:id])
  end

  def set_patient
    @patient = @school_move.patient

    @patient_with_changes =
      @patient.dup.tap do |patient|
        patient.clear_changes_information
        patient.school = @school_move.school
        patient.home_educated = @school_move.home_educated
      end
  end
end
