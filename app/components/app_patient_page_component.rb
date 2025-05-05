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
    @vaccinate_form = vaccinate_form || default_vaccinate_form
  end

  delegate :patient, :session, to: :patient_session

  def display_health_questions?
    consents.any?(&:response_given?)
  end

  def display_gillick_assessment_card?
    gillick_assessment.present? || gillick_assessment_can_be_recorded?
  end

  def gillick_assessment_can_be_recorded?
    patient_session.session.today? && helpers.policy(GillickAssessment).new?
  end

  def consents
    @consents ||= ConsentGrouper.call(patient.consents, programme:)
  end

  def gillick_assessment
    @gillick_assessment ||=
      patient_session
        .gillick_assessments
        .order(created_at: :desc)
        .find_by(programme:)
  end

  def vaccination_records
    patient
      .vaccination_records
      .where(programme:)
      .includes(:batch, :location, :performed_by_user, :programme, :vaccine)
      .order(:performed_at)
  end

  def default_vaccinate_form
    pre_screening_confirmed = patient.pre_screenings.today.exists?(programme:)

    VaccinateForm.new(patient_session:, programme:, pre_screening_confirmed:)
  end
end
