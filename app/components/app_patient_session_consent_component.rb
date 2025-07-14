# frozen_string_literal: true

class AppPatientSessionConsentComponent < ViewComponent::Base
  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def colour
    I18n.t(status, scope: %i[status consent colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status consent label])}"
  end

  def latest_consent_request
    @latest_consent_request ||=
      patient
        .consent_notifications
        .request
        .has_programme(programme)
        .order(sent_at: :desc)
        .first
  end

  def consent_status
    @consent_status ||= patient.consent_status(programme:)
  end

  def vaccination_status
    @vaccination_status ||= patient.vaccination_status(programme:)
  end

  def can_send_consent_request?
    consent_status.no_response? && patient.send_notifications? &&
      session.open_for_consent? && patient.parents.any?
  end

  def who_refused
    consents.find(&:response_refused?)&.who_responded
  end

  def consents
    @consents ||= ConsentGrouper.call(patient.consents, programme:)
  end

  def show_health_answers?
    consents.any?(&:response_given?)
  end

  delegate :status, to: :consent_status
end
