# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  include Wicked::Wizard

  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session
  before_action :set_assessment
  before_action :set_steps
  before_action :setup_wizard
  before_action :set_locations, only: %i[show update]

  def new
  end

  def create
    @assessment.assessor = current_user
    @assessment.save!

    redirect_to wizard_path(steps.first)
  end

  def show
    render_wizard
  end

  def update
    case step
    when :gillick, :location, :notes
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
    @assessment = authorize @patient_session.draft_gillick_assessment
  end

  def set_locations
    @locations = policy_scope(Location).community_clinic if step == :location
  end

  def set_steps
    self.steps = @assessment.wizard_steps
  end

  def finish_wizard_path
    session_patient_path(id: @patient.id)
  end

  def gillick_params
    params.fetch(:gillick_assessment, {}).permit(
      :gillick_competent,
      :location_name,
      :notes
    )
  end
end
