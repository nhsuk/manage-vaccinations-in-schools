# frozen_string_literal: true

class TextDeliveryJob < ApplicationJob
  queue_as -> { Rails.configuration.action_mailer.deliver_later_queue_name }

  def perform(
    template_name,
    session:,
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    vaccination_record: nil
  )
    template_id = GOVUK_NOTIFY_TEXT_TEMPLATES[template_name.to_sym]
    raise UnknownTemplate if template_id.nil?

    phone_number = consent_form&.parent_phone || parent&.phone
    return if phone_number.nil?

    unless consent_form&.parent_phone_receive_updates ||
             parent&.phone_receive_updates
      return
    end

    personalisation =
      GovukNotifyPersonalisation.call(
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        vaccination_record:
      )

    if self.class.send_via_notify?
      self.class.client.send_sms(phone_number:, template_id:, personalisation:)
    else
      Rails.logger.info "Sending text message to #{phone_number} with template #{template_id}"
    end
  end

  def self.client
    @client ||=
      Notifications::Client.new(
        Rails.configuration.action_mailer.notify_settings[:api_key]
      )
  end

  def self.send_via_notify?
    Rails.configuration.action_mailer.delivery_method == :notify
  end

  class UnknownTemplate < StandardError
  end
end
