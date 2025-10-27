# frozen_string_literal: true

class AppConsentSummaryComponent < ViewComponent::Base
  def initialize(consent, change_links: {})
    @consent = consent
    @change_links = change_links
  end

  def call = govuk_summary_list(rows:, actions: @change_links.present?)

  private

  attr_reader :consent, :change_links

  delegate :programme, to: :consent
  delegate :consent_response_tag, :govuk_summary_list, to: :helpers

  def rows
    [
      programme_row,
      date_row,
      method_row,
      response_row,
      injection_alternative_row,
      without_gelatine_row,
      notify_parents_on_vaccination_row,
      reason_for_refusal_row,
      notify_parent_on_refusal_row,
      notes_row
    ].compact
  end

  def programme_row
    {
      key: {
        text: "Programme"
      },
      value: {
        text:
          tag.strong(
            programme.name,
            class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
          )
      }
    }
  end

  def date_row
    return if consent.responded_at.nil?

    {
      key: {
        text: "Date"
      },
      value: {
        text: consent.responded_at.to_fs(:long)
      }
    }
  end

  def method_row
    {
      key: {
        text: "Method"
      },
      value: {
        text: consent.human_enum_name(:route).humanize
      },
      actions: [
        if (href = change_links[:route])
          { href:, visually_hidden_text: "method" }
        end
      ].compact
    }
  end

  def response_row
    {
      key: {
        text: "Response"
      },
      value: {
        text: consent_response_tag(consent)
      },
      actions: [
        if (href = change_links[:response])
          { href:, visually_hidden_text: "decision" }
        end
      ].compact
    }
  end

  def injection_alternative_row
    return unless consent.vaccine_method_nasal?

    {
      key: {
        text: "Consent also given for injected vaccine?"
      },
      value: {
        text: consent.vaccine_method_injection? ? "Yes" : "No"
      }
    }
  end

  def without_gelatine_row
    return if consent.without_gelatine.nil?

    {
      key: {
        text: "Consent given for gelatine-free vaccine only?"
      },
      value: {
        text: consent.without_gelatine ? "Yes" : "No"
      }
    }
  end

  def notify_parents_on_vaccination_row
    return if consent.notify_parents_on_vaccination.nil?

    {
      key: {
        text: "Confirmation of vaccination sent to parent?"
      },
      value: {
        text: consent.notify_parents_on_vaccination ? "Yes" : "No"
      },
      actions: [
        if (href = change_links[:notify_parents_on_vaccination])
          {
            href:,
            visually_hidden_text: "confirmation of vaccination sent to parent"
          }
        end
      ].compact
    }
  end

  def reason_for_refusal_row
    return if consent.reason_for_refusal.nil?

    {
      key: {
        text: "Reason for refusal"
      },
      value: {
        text: consent.human_enum_name(:reason_for_refusal)
      }
    }
  end

  def notify_parent_on_refusal_row
    return if consent.notify_parent_on_refusal.nil?

    {
      key: {
        text: "Confirmation of decision sent to parent?"
      },
      value: {
        text: consent.notify_parent_on_refusal ? "Yes" : "No"
      }
    }
  end

  def notes_row
    return if consent.notes.blank?

    { key: { text: "Notes" }, value: { text: consent.notes } }
  end
end
