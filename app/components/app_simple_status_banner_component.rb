# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  delegate :state, to: :@patient_session

  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  private

  def most_recent_triage
    @most_recent_triage ||= @patient_session.triage.order(:created_at).last
  end

  def most_recent_vaccination
    @most_recent_vaccination ||=
      @patient_session.vaccination_records.order(:created_at).last
  end

  def who_refused
    @patient_session
      .consents
      .response_refused
      .map(&:who_responded)
      .last
      &.capitalize
  end

  def full_name
    @patient_session.patient.full_name
  end

  def nurse
    most_recent_event = [
      most_recent_triage,
      most_recent_vaccination
    ].compact.max_by(&:created_at)

    most_recent_event&.performed_by&.full_name
  end

  def state
    @patient_session.state
  end

  def heading
    I18n.t("patient_session_statuses.#{state}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{state}.colour")
  end
end
