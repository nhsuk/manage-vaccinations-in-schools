# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def status
    @status ||= @patient_session.status(programme:)
  end

  private

  attr_reader :programme

  def who_refused
    @patient_session
      .latest_consents(programme:)
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
  end

  def full_name
    @patient_session.patient.full_name
  end

  def nurse
    (
      @patient_session.triages(programme:) +
        @patient_session.vaccination_records(programme:)
    ).max_by(&:updated_at)&.performed_by&.full_name
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end
end
