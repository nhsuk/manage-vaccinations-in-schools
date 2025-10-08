# frozen_string_literal: true

class AppConsentSummaryComponent < ViewComponent::Base
  def initialize(consent, change_links: {})
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
        row.with_key { "Response" }
        row.with_value { consent_response_tag(consent) }
        if (href = change_links[:response])
          row.with_action(
            text: "Change",
            visually_hidden_text: "decision",
            href:
          )
        end
      end

      if consent.vaccine_method_nasal?
        summary_list.with_row do |row|
          row.with_key { "Consent also given for injected vaccine?" }
          row.with_value { consent.vaccine_method_injection? ? "Yes" : "No" }
        end
      end

      unless consent.notify_parents_on_vaccination.nil?
        summary_list.with_row do |row|
          row.with_key { "Confirmation of vaccination sent to parent?" }
          row.with_value do
            consent.notify_parents_on_vaccination ? "Yes" : "No"
          end
          if (href = change_links[:notify_parents_on_vaccination])
            row.with_action(
              text: "Change",
              visually_hidden_text: "decision",
              href:
            )
          end
        end
      end

      if consent.reason_for_refusal.present?
        summary_list.with_row do |row|
          row.with_key { "Reason for refusal" }
          row.with_value { consent.human_enum_name(:reason_for_refusal) }
        end
      end

      unless consent.notify_parent_on_refusal.nil?
        summary_list.with_row do |row|
          row.with_key { "Confirmation of decision sent to parent?" }
          row.with_value { consent.notify_parent_on_refusal ? "Yes" : "No" }
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
  delegate :consent_response_tag, :govuk_summary_list, to: :helpers
end
