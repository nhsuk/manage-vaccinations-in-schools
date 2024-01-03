class AppConsentDetailsComponent < ViewComponent::Base
  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Name" }
        row.with_value { name }
      end

      unless self_consent?
        summary_list.with_row do |row|
          row.with_key { "Relationship" }
          row.with_value { who_responded }
        end

        summary_list.with_row do |row|
          row.with_key { "Contact" }
          row.with_value { parent_phone_and_email.join("<br />").html_safe }
        end
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
          row.with_value { reason_for_refusal }
        end
      end
    end
  end

  def initialize(consents:)
    super

    @consents = consents
  end

  private

  def self_consent?
    if @consents.first.respond_to?(:via_self_consent?)
      @consents.first.via_self_consent?
    else
      false
    end
  end

  def name
    if @consents.first.respond_to?(:via_self_consent?)
      @consents.first.name
    else
      @consents.first.parent_name
    end
  end

  def who_responded
    @consents.first.who_responded
  end

  def parent_phone_and_email
    [@consents.first.parent_phone, @consents.first.parent_email].compact
  end

  def refused_consents
    @refused_consents ||=
      if @consents.first.respond_to?(:response_refused?)
        @consents.find_all(&:response_refused?)
      else
        @consents.find_all(&:consent_refused?)
      end
  end

  def reason_for_refusal
    if refused_consents.first.respond_to?(:reason)
      refused_consents.first.human_enum_name(:reason)
    else
      refused_consents.first.human_enum_name(:reason_for_refusal)
    end
  end
end
