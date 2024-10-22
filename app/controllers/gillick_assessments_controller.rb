# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  include Wicked::Wizard

  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session
  before_action :set_assessment, only: %i[show update]
  before_action :set_steps
  before_action :setup_wizard

  def new
    authorize GillickAssessment
  end

  def create
    @assessment =
      @patient_session.gillick_assessments.build(assessor: current_user)
    authorize @assessment
    @assessment.save!

    redirect_to wizard_path(steps.first)
  end

  def show
    render_wizard
  end

  def update
    authorize @assessment

    case step
    when :gillick, :notes
      @assessment.assign_attributes(gillick_params.merge(wizard_step: step))
    when :confirm
      @assessment.assign_attributes(recorded_at: Time.zone.now)
    end

    render_wizard @assessment
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def set_session
    @session = policy_scope(Session).find(params[:session_id])
  end

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession).find_by(
        session_id: params[:session_id],
        patient_id: params[:patient_id]
      )
  end

  def set_assessment
    @assessment = @patient_session.draft_gillick_assessments.first
  end

  def set_steps
    self.steps = GillickAssessment.wizard_steps
  end

  def finish_wizard_path
    session_patient_path(id: @patient.id)
  end

  def gillick_params
    params.fetch(:gillick_assessment, {}).permit(:gillick_competent, :notes)
  end
end
