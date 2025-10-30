# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient, session, programme, consent)
    validate_consent_programme!(consent, programme)

    return unless send_notification?(patient, session, consent)

    params = { consent:, session:, sent_by: current_user }

    if consent.requires_triage?
      send_triage_email(
        patient,
        programme,
        consent,
        params,
        session.organisation
      )
    elsif consent.response_refused?
      send_confirmation_email_and_sms(:refused, consent, params)
    elsif consent.response_given?
      send_confirmation_email_and_sms(:given, consent, params)
    end
  end

  private

  def validate_consent_programme!(consent, programme)
    if consent.programme_id != programme.id
      raise "Consent is for a different programme."
    end
  end

  def send_notification?(patient, session, consent)
    patient.send_notifications?(team: session.team, send_to_archived: true) &&
      !consent.via_self_consent?
  end

  def send_triage_email(patient, programme, consent, params, organisation)
    triage_status =
      patient.triage_status(programme:, academic_year: consent.academic_year)

    template = triage_email_template(triage_status.status, organisation)
    EmailDeliveryJob.perform_later(template, **params)
  end

  def triage_email_template(status, organisation)
    case status
    when "safe_to_vaccinate"
      :triage_vaccination_will_happen
    when "do_not_vaccinate"
      :triage_vaccination_wont_happen
    when "invite_to_clinic"
      resolve_email_template(:triage_vaccination_at_clinic, organisation)
    else
      :consent_confirmation_triage
    end
  end

  def send_confirmation_email_and_sms(type, consent, params)
    template = :"consent_confirmation_#{type}"
    EmailDeliveryJob.perform_later(template, **params)

    if consent.parent.phone_receive_updates
      SMSDeliveryJob.perform_later(template, **params)
    end
  end

  def resolve_email_template(template_name, organisation)
    template_names = [
      :"#{template_name}_#{organisation.ods_code.downcase}",
      template_name
    ]
    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
