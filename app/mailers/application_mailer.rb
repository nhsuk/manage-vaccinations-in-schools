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

  def consent
    @consent ||= params[:consent]
  end

  def consent_form
    @consent_form ||= params[:consent_form]
  end

  def vaccination_record
    @vaccination_record ||= params[:vaccination_record]
  end

  def patient_session
    @patient_session ||= params[:patient_session]
  end

  def patient
    @patient ||= params[:patient]
  end

  def parent
    @parent ||= params[:parent]
  end

  def programme
    @programme ||= params[:programme]
  end

  def session
    @session ||= params[:session]
  end

  def sent_by
    @sent_by ||= params[:sent_by]
  end

  def to
    consent_form&.parent_email || consent&.parent&.email || parent.email
  end

  def reply_to_id
    team =
      session&.team || patient_session&.team || consent_form&.team ||
        vaccination_record&.team

    return team.reply_to_id if team&.reply_to_id

    organisation =
      session&.organisation || patient_session&.organisation ||
        consent_form&.organisation || consent&.organisation ||
        vaccination_record&.organisation

    organisation.reply_to_id
  end

  def personalisation
    GovukNotifyPersonalisation.call(
      consent:,
      consent_form:,
      patient:,
      patient_session:,
      programme:,
      session:,
      vaccination_record:
    )
  end

  def attach_data_for_notify_log_entry
    # https://stackoverflow.com/a/28004917

    patient_id = (patient || consent&.patient || patient_session&.patient)&.id
    consent_form_id = consent_form&.id

    message.instance_variable_set(:@consent_form_id, consent_form_id)
    message.instance_variable_set(:@patient_id, patient_id)
    message.instance_variable_set(:@sent_by_user_id, sent_by&.id)

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
        recipient_deterministic: recipient,
        sent_by_user_id: mail.sent_by_user_id,
        template_id: mail.template_id,
        type: :email
      )
    end
  end
end
