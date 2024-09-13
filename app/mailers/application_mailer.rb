# frozen_string_literal: true

class ApplicationMailer < Mail::Notify::Mailer
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
    @patient_session ||=
      params[:patient_session] || vaccination_record&.patient_session
  end

  def patient
    @patient ||=
      params[:patient] || consent&.patient || patient_session&.patient
  end

  def parent
    @parent ||= params[:parent] || consent&.parent
  end

  def session
    @session ||=
      params[:session] || consent_form&.session || patient_session&.session
  end

  def to
    consent_form&.parent_email || parent.email
  end

  def reply_to_id
    session.programme.team.reply_to_id
  end

  def personalisation
    GovukNotifyPersonalisation.call(
      consent:,
      consent_form:,
      parent:,
      patient:,
      session:,
      vaccination_record:
    )
  end
end
