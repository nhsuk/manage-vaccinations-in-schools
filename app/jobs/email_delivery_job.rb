# frozen_string_literal: true

class EmailDeliveryJob < NotifyDeliveryJob
  def perform(
    template_name,
    consent: nil,
    consent_form: nil,
    parent: nil,
    patient: nil,
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

    personalisation =
      GovukNotifyPersonalisation.call(
        session:,
        consent:,
        consent_form:,
        patient:,
        programme:,
        vaccination_record:
      )

    args = { email_address:, personalisation:, template_id: }

    if (
         email_reply_to_id =
           reply_to_id(consent:, consent_form:, session:, vaccination_record:)
       )
      args[:email_reply_to_id] = email_reply_to_id
    end

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

    patient ||= consent&.patient || vaccination_record&.patient

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

  def reply_to_id(consent:, consent_form:, session:, vaccination_record:)
    team = session&.team || consent_form&.team || vaccination_record&.team

    return team.reply_to_id if team&.reply_to_id

    organisation =
      session&.organisation || consent_form&.organisation ||
        consent&.organisation || vaccination_record&.organisation

    organisation.reply_to_id
  end
end
