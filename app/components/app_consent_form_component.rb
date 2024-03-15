class AppConsentFormComponent < ViewComponent::Base
  def initialize(consent_form:)
    super
    @consent_form = consent_form
  end

  def refusal_reason
    safe_join [
                @consent_form.human_enum_name(:reason),
                @consent_form.reason_notes
              ].compact,
              tag.br
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { @consent_form.parent_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Relationship" }
        row.with_value { @consent_form.who_responded }
      end

      summary_list.with_row do |row|
        row.with_key { "Contact" }
        row.with_value do
          safe_join(
            [@consent_form.parent_phone, @consent_form.parent_email].reject(
              &:blank?
            ),
            tag.br
          )
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value do
          render AppConsentResponseComponent::AppSingleConsentResponseComponent.new(
                   response:
                     @consent_form.human_enum_name(:response).capitalize,
                   route: "online",
                   timestamp: @consent_form.recorded_at
                 )
        end
      end

      if @consent_form.consent_refused?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value { refusal_reason }
        end
      end
    end
  end
end
