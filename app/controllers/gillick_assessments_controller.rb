# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  before_action :set_patient
  before_action :set_session
  before_action :set_patient_session

  def new
  end

  def create
    @draft_gillick_assessment =
      DraftGillickAssessment.new(request_session: session, current_user:).tap(
        &:reset!
      )

    if @draft_gillick_assessment.update(patient_session: @patient_session)
      redirect_to draft_gillick_assessment_path(Wicked::FIRST_STEP)
    else
      render :new, status: :unprocessable_entity
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
end
