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

  def to
    consent_form&.parent_email || consent&.parent&.email || parent.email
  end

  def reply_to_id
    team =
      session&.team || patient_session&.team || consent_form&.team ||
        consent&.team || vaccination_record&.team

    team.reply_to_id
  end

  def personalisation
    GovukNotifyPersonalisation.call(
      consent:,
      consent_form:,
      parent:,
      patient:,
      patient_session:,
      programme:,
      session:,
      vaccination_record:
    )
  end
end
