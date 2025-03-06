# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :current_user, :patient_session, :programme, :vaccinate_form

  def initialize(
    patient_session:,
    programme:,
    current_user: nil,
    triage: nil,
    vaccinate_form: nil
  )
    super

    @patient_session = patient_session
    @programme = programme
    @current_user = current_user
    @triage = triage
    @vaccinate_form = vaccinate_form || VaccinateForm.new
  end

  delegate :patient, :session, to: :patient_session

  def display_health_questions?
    patient_session.consent.latest[programme].any?(&:response_given?)
  end

  def display_gillick_assessment_card?
    patient_session.gillick_assessment(programme) ||
      gillick_assessment_can_be_recorded?
  end

  def gillick_assessment_can_be_recorded?
    patient_session.session.today? && helpers.policy(GillickAssessment).new?
  end
end
