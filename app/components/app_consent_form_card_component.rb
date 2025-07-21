# frozen_string_literal: true

class AppConsentFormCardComponent < ViewComponent::Base
  def initialize(consent_form)
    super

    @consent_form = consent_form
  end

  def call
    render AppCardComponent.new(heading_level: 2) do |card|
      card.with_heading { "Consent response" }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Programmes" }
          row.with_value do
            render AppProgrammeTagsComponent.new(@consent_form.programmes)
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Decision" }
          row.with_value do
            render AppTimestampedEntryComponent.new(
                     text: @consent_form.summary_with_route,
                     timestamp: @consent_form.recorded_at
                   )
          end
        end

        if show_refusal_row?
          summary_list.with_row do |row|
            row.with_key { "Refusal reason" }
            row.with_value { refusal_reason_details }
          end
        end
      end
    end
  end

  private

  def refusal_reason
    {
      reason: @consent_form.human_enum_name(:reason).presence,
      notes: @consent_form.reason_notes
    }
  end

  def show_refusal_row?
    [refusal_reason[:reason], refusal_reason[:notes]].compact_blank.any?
  end

  def refusal_reason_details
    safe_join(
      [refusal_reason[:reason]&.capitalize, refusal_reason_notes].compact_blank,
      "\n"
    )
  end

  def refusal_reason_notes
    if refusal_reason[:notes].present?
      tag.div(class: "nhsuk-u-margin-top-2 nhsuk-u-font-size-16") do
        refusal_reason[:notes]
      end
    end
  end
end
