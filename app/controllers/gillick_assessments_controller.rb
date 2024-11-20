# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session
  before_action :set_is_first_assessment
  before_action :set_gillick_assessment

  def edit
  end

  def update
    @gillick_assessment.assign_attributes(gillick_assessment_params)

    if !@gillick_assessment.changed? || @gillick_assessment.save
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

  def set_is_first_assessment
    @is_first_assessment = @patient_session.gillick_assessments.empty?
  end

  def set_gillick_assessment
    @gillick_assessment =
      authorize @patient_session.latest_gillick_assessment&.dup ||
                  @patient_session.gillick_assessments.build
  end

  def gillick_assessment_params
    params
      .require(:gillick_assessment)
      .permit(
        :knows_consequences,
        :knows_delivery,
        :knows_disease,
        :knows_side_effects,
        :knows_vaccination,
        :notes
      )
      .merge(performed_by: current_user)
  end
end
