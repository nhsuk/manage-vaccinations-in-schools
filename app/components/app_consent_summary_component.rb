# frozen_string_literal: true

class AppConsentSummaryComponent < ViewComponent::Base
  def initialize(consent, change_links: {})
    super

    @consent = consent
    @change_links = change_links
  end

  def call
    govuk_summary_list(actions: @change_links.present?) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Programme" }
        row.with_value do
          tag.strong(
            programme.name,
            class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
          )
        end
      end

      if consent.responded_at.present?
        summary_list.with_row do |row|
          row.with_key { "Date" }
          row.with_value { consent.responded_at.to_fs(:long) }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Method" }
        row.with_value { consent.human_enum_name(:route).humanize }
        if (href = change_links[:route])
          row.with_action(text: "Change", visually_hidden_text: "method", href:)
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Decision" }
        row.with_value { helpers.consent_status_tag(consent) }
        if (href = change_links[:response])
          row.with_action(
            text: "Change",
            visually_hidden_text: "decision",
            href:
          )
        end
      end

      consent
        .vaccine_methods
        .drop(1)
        .each do |vaccine_method|
          method_name = Vaccine.human_enum_name(:method_prefix, vaccine_method)

          summary_list.with_row do |row|
            row.with_key { "Consent also given for #{method_name} vaccine?" }
            row.with_value { "Yes" }
          end
        end

      if consent.reason_for_refusal.present?
        summary_list.with_row do |row|
          row.with_key { "Reason for refusal" }
          row.with_value { consent.human_enum_name(:reason_for_refusal) }
        end
      end

      if consent.notes.present?
        summary_list.with_row do |row|
          row.with_key { "Notes" }
          row.with_value { consent.notes }
        end
      end
    end
  end

  private

  attr_reader :consent, :change_links

  delegate :programme, to: :consent
end
