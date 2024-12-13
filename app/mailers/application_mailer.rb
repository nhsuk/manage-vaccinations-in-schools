# frozen_string_literal: true

class ApplicationMailer < Mail::Notify::Mailer
  before_action :attach_data_for_notify_log_entry
  after_deliver :log_delivery

  private

  def app_template_mail(template_name)
    template_mail(
      GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(template_name),
      to:,
      reply_to_id:,
      personalisation:
    )
  end

  def to
    parameters.consent_form&.parent_email || parameters.parent.email
  end

  def reply_to_id
    parameters.organisation.reply_to_id
  end

  def parameters
    @parameters ||=
      GovukNotifyParameters.new(
        **params.slice(
          :consent,
          :consent_form,
          :parent,
          :patient,
          :patient_session,
          :programme,
          :session,
          :vaccination_record
        )
      )
  end

  def personalisation
    GovukNotifyPersonalisation.call(parameters)
  end

  def attach_data_for_notify_log_entry
    # https://stackoverflow.com/a/28004917

    patient_id = parameters.patient&.id
    consent_form_id = parameters.consent_form&.id
    sent_by_user_id = params[:sent_by]&.id

    message.instance_variable_set(:@consent_form_id, consent_form_id)
    message.instance_variable_set(:@patient_id, patient_id)
    message.instance_variable_set(:@sent_by_user_id, sent_by_user_id)

    message.class.send(:attr_reader, :consent_form_id)
    message.class.send(:attr_reader, :patient_id)
    message.class.send(:attr_reader, :sent_by_user_id)
  end

  def log_delivery
    mail.to.map do |recipient|
      NotifyLogEntry.create!(
        consent_form_id: mail.consent_form_id,
        patient_id: mail.patient_id,
        recipient:,
        sent_by_user_id: mail.sent_by_user_id,
        template_id: mail.template_id,
        type: :email
      )
    end
  end
end
