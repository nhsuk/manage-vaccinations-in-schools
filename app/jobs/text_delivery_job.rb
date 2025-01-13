# frozen_string_literal: true

class TextDeliveryJob < ApplicationJob
  queue_as { Rails.configuration.action_mailer.deliver_later_queue_name }

  def perform(
    template_name,
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    patient_session: nil,
    programme: nil,
    sent_by: nil,
    session: nil,
    vaccination_record: nil
  )
    template_id = GOVUK_NOTIFY_TEXT_TEMPLATES[template_name.to_sym]
    raise UnknownTemplate if template_id.nil?

    phone_number =
      consent_form&.parent_phone || consent&.parent&.phone || parent&.phone
    return if phone_number.nil?

    personalisation =
      GovukNotifyPersonalisation.call(
        session:,
        consent:,
        consent_form:,
        patient:,
        patient_session:,
        programme:,
        vaccination_record:
      )

    delivery_id =
      if self.class.send_via_notify?
        response =
          self.class.client.send_sms(
            phone_number:,
            template_id:,
            personalisation:
          )
        response.id
      elsif self.class.send_via_test?
        self.class.deliveries << {
          phone_number:,
          template_id:,
          personalisation:
        }
        SecureRandom.uuid
      else
        Rails.logger.info "Sending text message to #{phone_number} with template #{template_id}"
        nil
      end

    patient ||= consent&.patient || patient_session&.patient

    NotifyLogEntry.create!(
      consent_form:,
      delivery_id:,
      patient:,
      recipient: phone_number,
      sent_by:,
      template_id:,
      type: :sms
    )
  end

  def self.client
    @client ||=
      Notifications::Client.new(
        Rails.configuration.action_mailer.notify_settings[:api_key]
      )
  end

  def self.deliveries
    @deliveries ||= []
  end

  def self.send_via_notify?
    Rails.configuration.action_mailer.delivery_method == :notify
  end

  def self.send_via_test?
    Rails.configuration.action_mailer.delivery_method == :test
  end

  class UnknownTemplate < StandardError
  end
end
