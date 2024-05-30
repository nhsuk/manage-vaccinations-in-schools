class GillickAssessmentsController < ApplicationController
  include Wicked::Wizard

  layout "two_thirds"

  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session
  before_action :set_assessment, only: %i[show update]

  steps :gillick, :confirm

  def new
  end

  def create
    @patient_session.create_gillick_assessment!(assessor: current_user)

    redirect_to wizard_path(steps.first)
  end

  def show
    render_wizard
  end

  def update
    case current_step
    when :gillick
      @assessment.assign_attributes(gillick_params)
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
        patient_id: params[:patient_id],
      )
  end

  def set_assessment
    @assessment = @patient_session.draft_gillick_assessment
  end

  def finish_wizard_path
    session_patient_path(id: @patient.id)
  end

  def current_step
    @current_step ||= wizard_value(step).to_sym
  end

  def gillick_params
    params.fetch(:gillick_assessment, {}).permit(:gillick_competent, :notes)
  end
end
