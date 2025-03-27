# frozen_string_literal: true

class AppConsentTableComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def render?
    consents.any?
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def consents
    @consents ||=
      patient.consent_outcome.all[programme].sort_by(&:created_at).reverse
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
