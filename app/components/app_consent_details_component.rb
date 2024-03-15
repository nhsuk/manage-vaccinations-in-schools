class AppConsentDetailsComponent < ViewComponent::Base
  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { consent.name }
      end

      unless consent.via_self_consent?
        summary_list.with_row do |row|
          row.with_key { "Relationship" }
          row.with_value { consent.who_responded }
        end

        summary_list.with_row do |row|
          row.with_key { "Contact" }
          row.with_value { contact_details }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value do
          render AppConsentResponseComponent.new(consents: @consents)
        end
      end

      if first_refused_consent.present?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value { refusal_reason }
        end
      end
    end
  end

  def initialize(consents:)
    super
    @consents = consents
  end

  private

  def consent
    @consents.first
  end

  def contact_details
    safe_join(
      [consent.parent_phone, consent.parent_email].reject(&:blank?),
      tag.br
    )
  end

  def refusal_reason
    safe_join(
      [
        first_refused_consent.human_enum_name(:reason_for_refusal),
        first_refused_consent.reason_for_refusal_notes
      ].compact,
      tag.br
    )
  end

  def first_refused_consent
    @first_refused_consent ||= @consents.find_all(&:response_refused?).first
  end
end
