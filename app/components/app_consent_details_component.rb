class AppConsentDetailsComponent < ViewComponent::Base
  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { parent_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Relationship" }
        row.with_value { who_responded }
      end

      summary_list.with_row do |row|
        row.with_key { "Contact" }
        row.with_value { parent_phone_and_email.join("<br />").html_safe }
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value do
          render AppConsentResponseComponent.new(consents: @consents)
        end
      end

      if refused_consents.any?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value do
            refused_consents.first.human_enum_name(:reason_for_refusal)
          end
        end
      end
    end
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  private

  def parent_name
    @consents.first.parent_name
  end

  def who_responded
    @consents.first.who_responded.capitalize
  end

  def parent_phone_and_email
    [@consents.first.parent_phone, @consents.first.parent_email].compact
  end

  def refused_consents
    @refused_consents ||= @consents.find_all(&:response_refused?)
  end
end
