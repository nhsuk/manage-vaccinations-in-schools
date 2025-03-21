# frozen_string_literal: true

class AppConsentComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def consents
    @consents ||=
      patient
        .consents
        .where(programme:)
        .includes(:consent_form, :parent)
        .order(created_at: :desc)
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

  def can_send_consent_request?
    consent_status.no_response? && patient.send_notifications? &&
      session.open_for_consent? && patient.parents.any?
  end

  def status_colour(consent)
    if consent.invalidated? || consent.withdrawn?
      "grey"
    elsif consent.response_given?
      "aqua-green"
    elsif consent.response_refused?
      "red"
    else
      "grey"
    end
  end
end
