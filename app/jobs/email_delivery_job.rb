# frozen_string_literal: true

class EmailDeliveryJob < NotifyDeliveryJob
  include NotifyThrottlingConcern

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
    template_id = GOVUK_NOTIFY_EMAIL_TEMPLATES[template_name.to_sym]
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

    email_address =
      personalisation.consent_form&.parent_email ||
        personalisation.parent&.email
    return if email_address.nil?

    args = {
      email_address:,
      personalisation: personalisation.to_h,
      template_id:
    }

    if (
         email_reply_to_id =
           personalisation.subteam&.reply_to_id ||
             personalisation.team.reply_to_id
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

    NotifyLogEntry.create!(
      consent_form: personalisation.consent_form,
      delivery_id:,
      parent: personalisation.parent,
      patient: personalisation.patient,
      programme_ids: personalisation.programmes.map(&:id),
      recipient: email_address,
      sent_by:,
      template_id:,
      type: :email
    )
  end
end
