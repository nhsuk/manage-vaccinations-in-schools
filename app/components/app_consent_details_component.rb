class AppConsentDetailsComponent < ViewComponent::Base
  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { first_consent.name }
      end

      unless first_consent.via_self_consent?
        summary_list.with_row do |row|
          row.with_key { "Relationship" }
          row.with_value { first_consent.who_responded }
        end

        summary_list.with_row do |row|
          row.with_key { "Contact" }
          row.with_value { parent_phone_and_email_details }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value do
          render AppConsentResponseComponent.new(consents: @consents)
        end
      end

      if reason_for_refusal_details.present?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value { reason_for_refusal_details }
        end
      end
    end
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  private

  def parent_phone_and_email_details
    safe_join [first_consent.parent_phone, first_consent.parent_email].compact,
              tag.br
  end

  def refused_consents
    @refused_consents ||= @consents.find_all(&:response_refused?)
  end

  def reason_for_refusal_details
    safe_join [
                first_refused_consent.human_enum_name(:reason_for_refusal),
                first_refused_consent.reason_for_refusal_notes
              ].compact,
              tag.br
  end

  def first_consent
    @consents.first
  end

  def first_refused_consent
    refused_consents.first
  end
end
