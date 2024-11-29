# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_consent_form_confirmation(consent_form)
    mailer = ConsentMailer.with(consent_form:)

    if consent_form.contact_injection?
      mailer.confirmation_injection.deliver_later
    elsif consent_form.consent_refused?
      mailer.confirmation_refused.deliver_later
      TextDeliveryJob.perform_later(
        :consent_confirmation_refused,
        consent_form:
      )
    elsif consent_form.needs_triage?
      mailer.confirmation_triage.deliver_later
    elsif consent_form.actual_upcoming_session ==
          consent_form.organisation.generic_clinic_session ||
          consent_form.actual_upcoming_session&.completed?
      mailer.confirmation_clinic.deliver_later
    else
      mailer.confirmation_given.deliver_later
      TextDeliveryJob.perform_later(:consent_confirmation_given, consent_form:)
    end
  end
end
