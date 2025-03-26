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
    patient.latest_consents(programme:).any?(&:response_given?)
  end

  def display_gillick_assessment_card?
    patient_session.gillick_assessment(programme) ||
      gillick_assessment_can_be_recorded?
  end

  def gillick_assessment_can_be_recorded?
    patient_session.session.today? && helpers.policy(GillickAssessment).new?
  end

  def vaccination_records
    patient
      .vaccination_records
      .where(programme:)
      .includes(:batch, :location, :performed_by_user, :programme, :vaccine)
      .order(:performed_at)
  end

  def default_vaccinate_form
    pre_screening = patient_session.pre_screenings.last

    VaccinateForm.new(
      feeling_well: pre_screening&.feeling_well,
      knows_vaccination: pre_screening&.knows_vaccination,
      no_allergies: pre_screening&.no_allergies,
      not_already_had: pre_screening&.not_already_had,
      not_pregnant: pre_screening&.not_pregnant,
      not_taking_medication: pre_screening&.not_taking_medication,
      pre_screening_notes: pre_screening&.notes || ""
    )
  end
end
