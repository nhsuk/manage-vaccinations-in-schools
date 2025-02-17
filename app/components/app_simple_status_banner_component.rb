# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  delegate :patient, :status, to: :@patient_session

  private

  delegate :full_name, to: :patient

  def who_refused
    @patient_session
      .latest_consents(programme:)
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
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

  def programme
    @patient_session.programmes.first # TODO: handle multiple programmes
  end
end
