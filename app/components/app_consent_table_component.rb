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
      patient
        .consents
        .where(programme:)
        .includes(:consent_form, :parent, :programme)
        .order(created_at: :desc)
  end
end
