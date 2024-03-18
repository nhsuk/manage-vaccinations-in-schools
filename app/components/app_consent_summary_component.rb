class AppConsentSummaryComponent < ViewComponent::Base
  attr_reader :name, :relationship, :contact, :refusal_reason, :response

  def initialize(name:, relationship:, contact:, refusal_reason:, response: nil)
    super
    @name = name
    @relationship = relationship
    @contact = contact
    @refusal_reason = refusal_reason
    @response = response
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { name }
      end

      unless relationship.nil?
        summary_list.with_row do |row|
          row.with_key { "Relationship" }
          row.with_value { relationship.capitalize }
        end
      end

      unless contact.nil?
        summary_list.with_row do |row|
          row.with_key { "Contact" }
          row.with_value { contact_details }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Response" }
        row.with_value { response_details }
      end

      if refusal_reason_details.present?
        summary_list.with_row do |row|
          row.with_key { "Refusal reason" }
          row.with_value { refusal_reason_details }
        end
      end
    end
  end

  private

  def contact_details
    safe_join([contact[:phone], contact[:email]].reject(&:blank?), tag.br)
  end

  def response_details
    render AppTimestampedEntryComponent.new(
             text: @response[:text],
             timestamp: @response[:timestamp],
             recorded_by: @response[:recorded_by]
           )
  end

  def refusal_reason_details
    safe_join(
      [refusal_reason[:reason]&.capitalize, refusal_reason[:notes]].reject(&:blank?),
      tag.br
    )
  end
end
