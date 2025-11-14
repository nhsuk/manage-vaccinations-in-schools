# frozen_string_literal: true

class PatientSessions::GillickAssessmentsController < PatientSessions::BaseController
  before_action :set_gillick_assessment

  def edit
  end

  def update
    @gillick_assessment.assign_attributes(gillick_assessment_params)

    if @gillick_assessment.valid?
      @gillick_assessment.dup.save! if @gillick_assessment.changed?

      redirect_to session_patient_programme_path(@session, @patient, @programme)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_gillick_assessment
    @gillick_assessment =
      @patient
        .gillick_assessments
        .order(created_at: :desc)
        .find_or_initialize_by(
          date: Date.current,
          location: @session.location,
          programme: @programme
        )
  end

  def gillick_assessment_params
    params.expect(
      gillick_assessment: %i[
        knows_consequences
        knows_delivery
        knows_disease
        knows_side_effects
        knows_vaccination
        notes
      ]
    ).merge(performed_by: current_user)
  end
end
