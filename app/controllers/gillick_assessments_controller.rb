# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session
  before_action :set_gillick_assessment

  def new
  end

  def create
    if @gillick_assessment.update(
         performed_by: current_user,
         **gillick_assessment_params
       )
      redirect_to session_patient_path(id: @patient.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @gillick_assessment.update(gillick_assessment_params)
      redirect_to session_patient_path(id: @patient.id)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession).find_by(session: @session, patient: @patient)
  end

  def set_gillick_assessment
    @gillick_assessment =
      authorize @patient_session.gillick_assessment ||
                  @patient_session.build_gillick_assessment
  end

  def gillick_assessment_params
    params.require(:gillick_assessment).permit(
      :knows_consequences,
      :knows_delivery,
      :knows_disease,
      :knows_side_effects,
      :knows_vaccination,
      :notes
    )
  end
end
