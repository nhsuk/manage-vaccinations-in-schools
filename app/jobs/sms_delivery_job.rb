# frozen_string_literal: true

class SMSDeliveryJob < NotifyDeliveryJob
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
    template_id = GOVUK_NOTIFY_SMS_TEMPLATES[template_name.to_sym]
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

    args = { personalisation:, phone_number:, template_id: }

    delivery_id =
      if self.class.send_via_notify?
        self.class.client.send_sms(**args).id
      elsif self.class.send_via_test?
        self.class.deliveries << args
        SecureRandom.uuid
      else
        Rails.logger.info "Sending SMS to #{phone_number} with template #{template_id}"
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
end
