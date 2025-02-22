# frozen_string_literal: true

class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :section, :tab, :programme

  def initialize(patient_session:, programme:, section:, tab:)
    super

    @patient_session = patient_session
    @programme = programme
    @section = section
    @tab = tab
  end

  delegate :patient, :session, to: :patient_session

  def consents
    @consents ||=
      patient_session.consents(programme:).sort_by(&:created_at).reverse
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
    patient_session.no_consent?(programme:) && patient.send_notifications? &&
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
