# frozen_string_literal: true

class AppConsentCardComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

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

  def can_send_consent_request?
    patient.consent_outcome.no_response?(programme) &&
      patient.send_notifications? && session.open_for_consent? &&
      patient.parents.any?
  end

  def who_refused
    patient.consent_outcome.latest[programme]
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
  end

  private

  def status
    patient.consent_outcome.status[programme]
  end
end
