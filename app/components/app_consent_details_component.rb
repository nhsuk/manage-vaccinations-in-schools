class AppConsentDetailsComponent < ViewComponent::Base
  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { @consent.parent_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Relationship" }
        row.with_value { @consent.who_responded.capitalize }
      end

      summary_list.with_row do |row|
        row.with_key { "Contact" }
        row.with_value do
          [@consent.parent_phone, @consent.parent_email].compact
            .join("<br />")
            .html_safe
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value do
          render AppConsentResponseComponent.new(consents: [@consent])
        end
      end

      if @consent.response_refused?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value { @consent.human_enum_name(:reason_for_refusal) }
        end
      end
    end
  end

  def initialize(consent:)
    super

    @consent = consent
  end

  def summary
    response = @consent.human_enum_name(:response).capitalize
    by_whom = @consent.parent_name
    relationship = @consent.human_enum_name(:parent_relationship).capitalize
    "#{response} by #{by_whom} (#{relationship})"
  end
end
