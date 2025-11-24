# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient, session, programme, consent, triage)
    validate_consent_programme!(consent, programme)

    return unless send_notification?(patient, session, consent)

    params = { consent:, session:, sent_by: current_user }

    if triage
      send_triage_email(triage, session.organisation, params)
    elsif consent.requires_triage?
      send_consent_email(:triage, params)
    elsif consent.response_refused?
      send_consent_email_and_sms(:refused, consent, params)
    elsif consent.response_given?
      send_consent_email_and_sms(:given, consent, params)
    end
  end

  private

  def validate_consent_programme!(consent, programme)
    if consent.programme_type != programme.type
      raise "Consent is for a different programme."
    end
  end

  def send_notification?(patient, session, consent)
    patient.send_notifications?(team: session.team, send_to_archived: true) &&
      !consent.via_self_consent?
  end

  def send_triage_email(triage, organisation, params)
    template = triage_email_template(triage, organisation)
    EmailDeliveryJob.perform_later(template, **params)
  end

  def triage_email_template(triage, organisation)
    if triage.safe_to_vaccinate?
      :triage_vaccination_will_happen
    elsif triage.do_not_vaccinate?
      :triage_vaccination_wont_happen
    elsif triage.delay_vaccination?
      :triage_delay_vaccination
    elsif triage.invite_to_clinic?
      resolve_email_template(:triage_vaccination_at_clinic, organisation)
    elsif triage.keep_in_triage?
      :consent_confirmation_triage
    end
  end

  def send_consent_email(type, params)
    template = :"consent_confirmation_#{type}"
    EmailDeliveryJob.perform_later(template, **params)
  end

  def send_consent_sms(type, consent, params)
    if consent.parent.phone_receive_updates
      template = :"consent_confirmation_#{type}"
      SMSDeliveryJob.perform_later(template, **params)
    end
  end

  def send_consent_email_and_sms(type, consent, params)
    send_consent_email(type, params)
    send_consent_sms(type, consent, params)
  end

  def resolve_email_template(template_name, organisation)
    template_names = [
      :"#{template_name}_#{organisation.ods_code.downcase}",
      template_name
    ]
    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
