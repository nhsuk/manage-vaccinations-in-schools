class AppSimpleStatusBannerComponent < ViewComponent::Base
  delegate :state, to: :@patient_session

  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  def call
    render AppCardComponent.new(heading:, feature: true, colour:) do
      tag.p do
        I18n.t(
          "patient_session_statuses.#{state}.banner_explanation",
          default: "",
          full_name:,
          triage_nurse:,
          vaccination_nurse:,
          who_responded:,
          who_refused:
        )
      end
    end
  end

  private

  def consent
    # HACK: Component needs to be updated to work with multiple consents.
    @consent ||= @patient_session.consents.first
  end

  def most_recent_triage
    @most_recent_triage ||= @patient_session.triage.order(:created_at).last
  end

  def most_recent_vaccination
    @most_recent_vaccination ||=
      @patient_session.vaccination_records.order(:created_at).last
  end

  def who_responded
    consent&.who_responded&.downcase
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

  def triage_nurse
    most_recent_triage&.user&.full_name
  end

  def vaccination_nurse
    most_recent_vaccination&.user&.full_name
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
