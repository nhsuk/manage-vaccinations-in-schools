# frozen_string_literal: true

class EmailDeliveryJob < NotifyDeliveryJob
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
    template_id = GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name.to_sym]
    raise UnknownTemplate if template_id.nil?

    parent ||= consent&.parent

    email_address = consent_form&.parent_email || parent&.email
    return if email_address.nil?

    organisation =
      session&.organisation || patient_session&.organisation ||
        consent_form&.organisation || consent&.organisation ||
        vaccination_record&.organisation

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

    args = {
      email_address:,
      email_reply_to_id: organisation.reply_to_id,
      personalisation:,
      template_id:
    }

    delivery_id =
      if self.class.send_via_notify?
        self.class.client.send_email(**args).id
      elsif self.class.send_via_test?
        self.class.deliveries << args
        SecureRandom.uuid
      else
        Rails.logger.info "Sending email to #{email_address} with template #{template_id}"
        nil
      end

    patient ||= consent&.patient || patient_session&.patient

    NotifyLogEntry.create!(
      consent_form:,
      delivery_id:,
      parent:,
      patient:,
      recipient: email_address,
      sent_by:,
      template_id:,
      type: :email
    )
  end
end
