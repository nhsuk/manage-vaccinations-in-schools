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
          tag.p(class: "nhsuk-u-margin-bottom-0") do
            "#{@consent.human_enum_name(:response).capitalize} (online)"
          end \
          + tag.p(class: "nhsuk-u-margin-bottom-2 nhsuk-u-secondary-text-color nhsuk-u-font-size-16 nhsuk-u-margin-bottom-0") do
            (@consent.created_at.to_fs(:nhsuk_date_short_month) +
             tag.span(" at #{@consent.created_at.strftime('%-l:%M%P')}", class: "nhsuk-u-margin-left-1")).html_safe
          end
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
