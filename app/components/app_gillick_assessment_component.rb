# frozen_string_literal: true

class AppGillickAssessmentComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    @patient_session = patient_session
    @programme = programme
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session
  delegate :govuk_button_link_to, :policy, to: :helpers

  def gillick_assessment
    @gillick_assessment ||=
      patient_session
        .gillick_assessments
        .order(created_at: :desc)
        .find_by(programme:)
  end

  def can_assess?
    @can_assess ||=
      patient_session.session.today? && policy(GillickAssessment).new?
  end
end
