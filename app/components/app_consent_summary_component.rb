# frozen_string_literal: true

class AppConsentSummaryComponent < ViewComponent::Base
  def initialize(consent, change_links: {})
    super

    @consent = consent
    @change_links = change_links
  end

  def call
    govuk_summary_list(
      actions: @change_links.present?,
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      if @consent.recorded?
        summary_list.with_row do |row|
          row.with_key { "Response date" }
          row.with_value { @consent.responded_at.to_fs(:long) }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Decision" }
        row.with_value { helpers.consent_decision(@consent) }
        if (href = @change_links[:response])
          row.with_action(
            text: "Change",
            visually_hidden_text: "decision",
            href:
          )
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response method" }
        row.with_value { @consent.human_enum_name(:route).humanize }
        if (href = @change_links[:route])
          row.with_action(
            text: "Change",
            visually_hidden_text: "response method",
            href:
          )
        end
      end

      if @consent.reason_for_refusal.present?
        summary_list.with_row do |row|
          row.with_key { "Reason for refusal" }
          row.with_value { @consent.human_enum_name(:reason_for_refusal) }
        end
      end

      if @consent.notes.present?
        summary_list.with_row do |row|
          row.with_key { "Notes" }
          row.with_value { @consent.notes }
        end
      end
    end
  end
end
