# frozen_string_literal: true

module TriageMailerConcern
  extend ActiveSupport::Concern

  def send_triage_confirmation(patient_session, programme, consent)
    if consent.programme_id != programme.id
      raise "Consent is for a different programme."
    end

    session = patient_session.session
    patient = patient_session.patient
    organisation = patient_session.organisation

    return unless patient.send_notifications?
    return if consent.via_self_consent?

    params = { consent:, session:, sent_by: current_user }

    if vaccination_will_happen?(patient, programme, consent)
      EmailDeliveryJob.perform_later(:triage_vaccination_will_happen, **params)
    elsif vaccination_wont_happen?(patient, programme, consent)
      EmailDeliveryJob.perform_later(:triage_vaccination_wont_happen, **params)
    elsif vaccination_at_clinic?(patient, programme, consent)
      email_template =
        resolve_email_template(:triage_vaccination_at_clinic, organisation)
      EmailDeliveryJob.perform_later(email_template, **params)
    elsif consent.requires_triage?
      EmailDeliveryJob.perform_later(:consent_confirmation_triage, **params)
    elsif consent.response_refused?
      EmailDeliveryJob.perform_later(:consent_confirmation_refused, **params)

      if consent.parent.phone_receive_updates
        SMSDeliveryJob.perform_later(:consent_confirmation_refused, **params)
      end
    elsif consent.response_given?
      EmailDeliveryJob.perform_later(:consent_confirmation_given, **params)

      if consent.parent.phone_receive_updates
        SMSDeliveryJob.perform_later(:consent_confirmation_given, **params)
      end
    end
  end

  private

  def vaccination_will_happen?(patient, programme, consent)
    consent.requires_triage? &&
      patient.triage_status(
        programme:,
        academic_year: consent.academic_year
      ).safe_to_vaccinate?
  end

  def vaccination_wont_happen?(patient, programme, consent)
    consent.requires_triage? &&
      patient.triage_status(
        programme:,
        academic_year: consent.academic_year
      ).do_not_vaccinate?
  end

  def vaccination_at_clinic?(patient, programme, consent)
    consent.requires_triage? &&
      patient.triage_status(
        programme:,
        academic_year: consent.academic_year
      ).delay_vaccination?
  end

  def resolve_email_template(template_name, organisation)
    template_names = [
      :"#{template_name}_#{organisation.ods_code.downcase}",
      template_name
    ]
    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
