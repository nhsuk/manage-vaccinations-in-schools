# frozen_string_literal: true

class SMSDeliveryJob < NotifyDeliveryJob
  include NotifyThrottlingConcern

  INVALID_UK_MOBILE_NUMBER_ERROR = "InvalidPhoneError: Not a UK mobile number"

  def perform(
    template_name,
    academic_year: nil,
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
    programme_types: [],
    sent_by: nil,
    session: nil,
    team: nil,
    vaccination_record: nil
  )
    template_name_sym = template_name.to_sym
    personalisation =
      GovukNotifyPersonalisation.new(
        academic_year:,
        consent:,
        consent_form:,
        parent:,
        patient:,
        programme_types:,
        session:,
        team:,
        vaccination_record:
      )

    phone_number =
      if template_name_sym == :consent_unknown_contact_details_warning
        personalisation.parent&.phone
      else
        personalisation.consent_form&.parent_phone ||
          personalisation.parent&.phone
      end
    return if phone_number.nil?

    sms_renderer = NotifyTemplateRenderer.for(:sms)
    template_id, personalisation_hash =
      if use_local_template?(template_name_sym)
        rendered = sms_renderer.render(template_name_sym, personalisation)
        [
          sms_renderer.passthrough_template_id,
          { body: rendered[:body] }
        ]
      else
        tid = sms_renderer.template_id_for(template_name_sym)
        raise UnknownTemplate if tid.nil?
        [tid, personalisation.to_h]
      end

    args = {
      personalisation: personalisation_hash,
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
      recipient: phone_number,
      sent_by:,
      template_id:,
      type: :sms,
      notify_log_entry_programmes_attributes:
        personalisation.programmes.map do
          { programme_type: it.type, disease_types: it.disease_types }
        end
    )
  end

  def use_local_template?(template_name_sym)
    return false unless passthrough_sms_configured?

    NotifyTemplateRenderer.for(:sms).template_exists?(template_name_sym)
  end

  def passthrough_sms_configured?
    NotifyTemplateRenderer.for(:sms).passthrough_configured?
  end
end
