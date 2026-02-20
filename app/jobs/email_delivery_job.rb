# frozen_string_literal: true

class EmailDeliveryJob < NotifyDeliveryJob
  include NotifyThrottlingConcern

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

    email_address =
      if template_name_sym == :consent_unknown_contact_details_warning
        personalisation.parent&.email
      else
        personalisation.consent_form&.parent_email ||
          personalisation.parent&.email
      end

    return if email_address.nil?

    email_renderer = NotifyTemplateRenderer.for(:email)
    template_id, personalisation_hash =
      if use_local_template?(template_name_sym)
        rendered = email_renderer.render(template_name_sym, personalisation)
        [
          email_renderer.passthrough_template_id,
          { subject: rendered[:subject], body: rendered[:body] }
        ]
      else
        tid = email_renderer.template_id_for(template_name_sym)
        raise UnknownTemplate if tid.nil?
        [tid, personalisation.to_h]
      end

    args = {
      email_address:,
      personalisation: personalisation_hash,
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
        begin
          self.class.client.send_email(**args).id
        rescue Notifications::Client::BadRequestError => e
          if !Rails.env.production? &&
               e.message.include?(TEAM_ONLY_API_KEY_MESSAGE)
            # Prevent retries and job failures.
            Sentry.capture_exception(e)
          else
            raise
          end
        end
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
      recipient: email_address,
      sent_by:,
      template_id:,
      type: :email,
      notify_log_entry_programmes_attributes:
        personalisation.programmes.map do
          { programme_type: it.type, disease_types: it.disease_types }
        end
    )
  end

  def use_local_template?(template_name_sym)
    return false unless passthrough_email_configured?

    NotifyTemplateRenderer.for(:email).template_exists?(template_name_sym)
  end

  def passthrough_email_configured?
    NotifyTemplateRenderer.for(:email).passthrough_configured?
  end
end
