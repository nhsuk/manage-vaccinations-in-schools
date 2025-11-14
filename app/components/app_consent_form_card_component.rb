# frozen_string_literal: true

class AppConsentFormCardComponent < ViewComponent::Base
  def initialize(consent_form)
    @consent_form = consent_form
  end

  def call
    render AppCardComponent.new do |card|
      card.with_heading(level: 2) { "Consent response" }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Programmes" }
          row.with_value { render AppProgrammeTagsComponent.new(programmes) }
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

  delegate :govuk_summary_list, to: :helpers

  def programmes
    @consent_form.consent_form_programmes.map(&:programme)
  end

  def refusal_reason
    {
      title: @consent_form.human_enum_name(:reason_for_refusal),
      notes: @consent_form.reason_for_refusal_notes
    }
  end

  def show_refusal_row? = refusal_reason.values.any?(&:present?)

  def refusal_reason_details
    safe_join(
      [refusal_reason[:title], refusal_reason_notes].compact_blank,
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
