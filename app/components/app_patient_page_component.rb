# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :patient_session, :current_user, :section, :tab, :vaccinate_form

  def initialize(
    patient_session:,
    section:,
    tab:,
    current_user: nil,
    triage: nil,
    vaccinate_form: nil
  )
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
    @current_user = current_user
    @triage = triage
    @vaccinate_form = vaccinate_form || VaccinateForm.new
  end

  delegate :patient, :session, to: :patient_session

  def display_health_questions?
    patient_session.consents.any?(&:response_given?)
  end

  def display_gillick_assessment_card?
    gillick_assessment_can_be_recorded? || gillick_assessment_recorded?
  end

  def gillick_assessment_can_be_recorded?
    patient_session.session.today? && helpers.policy(GillickAssessment).new?
  end

  def gillick_assessment_recorded?
    patient_session.latest_gillick_assessment.present?
  end
end
