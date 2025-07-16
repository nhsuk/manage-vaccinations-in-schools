# frozen_string_literal: true

class AppConsentCardComponent < ViewComponent::Base
  def initialize(consent, session:)
    super

    @consent = consent
    @session = session
  end

  def call
    render AppCardComponent.new(**card_options) do |card|
      card.with_heading { heading }
      govuk_summary_list(rows:)
    end
  end

  private

  attr_reader :consent, :session

  delegate :patient, :programme, to: :consent

  def link_to
    session_patient_programme_consent_path(session, patient, programme, consent)
  end

  def card_options = { link_to:, colour: "offset", compact: true }

  def heading
    if consent.via_self_consent?
      consent.who_responded
    else
      "#{consent.name} (#{consent.who_responded})"
    end
  end

  def rows
    [
      if (phone = consent.parent&.phone).present?
        { key: { text: "Phone number" }, value: { text: phone } }
      end,
      if (email = consent.parent&.email).present?
        { key: { text: "Email address" }, value: { text: email } }
      end,
      {
        key: {
          text: "Date"
        },
        value: {
          text: consent.responded_at.to_fs(:long)
        }
      },
      {
        key: {
          text: "Decision"
        },
        value: {
          text: helpers.consent_status_tag(consent)
        }
      },
      if consent.vaccine_method_nasal?
        {
          key: {
            text: "Consent also given for injected vaccine?"
          },
          value: {
            text: consent.vaccine_method_injection? ? "Yes" : "No"
          }
        }
      end
    ].compact
  end
end
