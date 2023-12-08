class AppStatusBannerComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(heading: title, feature: true, colour:) do
      tag.p do
        explanation
      end
    end %>
  ERB
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  def title
    I18n.t(
      "patient_session_statuses.#{state}.banner_title",
      full_name:,
      who_responded:
    )
  end

  def explanation
    if state == "unable_to_vaccinate"
      reason_for_refusal =
        I18n.t(
          "patient_session_statuses.#{state}.banner_explanation.#{vaccination_record.reason}",
          full_name:
        )
      gave_consent =
        I18n.t(
          "patient_session_statuses.#{state}.banner_explanation.gave_consent",
          who_responded:
        )

      "#{reason_for_refusal}\n<br />\n#{gave_consent}".html_safe
    else
      I18n.t(
        "patient_session_statuses.#{state}.banner_explanation",
        default: "",
        full_name:,
        triage_nurse:,
        who_responded:,
        who_refused:
      )
    end
  end

  def colour
    I18n.t("patient_session_statuses.#{state}.colour")
  end

  private

  def consent
    # HACK: Component needs to be updated to work with multiple consents.
    @consent ||= @patient_session.consents.first
  end

  def vaccination_record
    @vaccination_record ||= @patient_session.vaccination_record
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
    @patient_session.triage.last&.user&.full_name
  end

  def state
    @patient_session.state
  end
end
