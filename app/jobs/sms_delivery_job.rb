# frozen_string_literal: true

class SMSDeliveryJob < NotifyDeliveryJob
  include NotifyThrottlingConcern

  INVALID_UK_MOBILE_NUMBER_ERROR = "InvalidPhoneError: Not a UK mobile number"

  def perform(
    template_name,
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    programmes: [],
    sent_by: nil,
    session: nil,
    vaccination_record: nil
  )
    template_id = GOVUK_NOTIFY_SMS_TEMPLATES[template_name.to_sym]
    raise UnknownTemplate if template_id.nil?

    personalisation =
      GovukNotifyPersonalisation.new(
        session:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        programmes:,
        vaccination_record:
      )

    phone_number =
      if template_name == :consent_unknown_contact_details_warning
        personalisation.parent&.phone
      else
        personalisation.consent_form&.parent_phone ||
          personalisation.parent&.phone
      end
    return if phone_number.nil?

    args = {
      personalisation: personalisation.to_h,
      phone_number:,
      template_id:
    }

    delivery_id, delivery_status =
      if self.class.send_via_notify?
        begin
          [self.class.client.send_sms(**args).id, "sending"]
        rescue Notifications::Client::BadRequestError => e
          if !Rails.env.production? &&
               e.message.include?(TEAM_ONLY_API_KEY_MESSAGE)
            # Prevent retries and job failures.
            Sentry.capture_exception(e)
            [nil, "technical_failure"]
          elsif e.message == INVALID_UK_MOBILE_NUMBER_ERROR
            [nil, "not_uk_mobile_number_failure"]
          else
            raise
          end
        end
      elsif self.class.send_via_test?
        self.class.deliveries << args
        [SecureRandom.uuid, "delivered"]
      else
        Rails.logger.info "Sending SMS to #{phone_number} with template #{template_id}"
        [nil, "delivered"]
      end

    NotifyLogEntry.create!(
      consent_form: personalisation.consent_form,
      delivery_id:,
      delivery_status:,
      parent: personalisation.parent,
      patient: personalisation.patient,
      programme_ids: personalisation.programmes.map(&:id),
      programme_types: personalisation.programmes.map(&:type),
      recipient: phone_number,
      sent_by:,
      template_id:,
      type: :sms
    )
  end
end
