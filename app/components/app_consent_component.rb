# frozen_string_literal: true

class AppConsentComponent < ViewComponent::Base
  attr_reader :patient_session, :section, :tab

  def initialize(patient_session:, section:, tab:)
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session

  def consents
    @consents ||= patient_session.consents.recorded.order(recorded_at: :desc)
  end

  def latest_consent_request
    @latest_consent_request ||=
      patient
        .consent_notifications
        .request
        .where(programme: session.programmes)
        .order(sent_at: :desc)
        .first
  end
end
