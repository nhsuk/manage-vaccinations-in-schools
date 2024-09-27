# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_consent_form_confirmation(consent_form)
    mailer = ConsentMailer.with(consent_form:)

    if consent_form.contact_injection?
      mailer.confirmation_injection.deliver_later
    elsif consent_form.consent_refused?
      mailer.confirmation_refused.deliver_later
      TextDeliveryJob.perform_later(:consent_refused, consent_form:)
    elsif consent_form.needs_triage?
      mailer.confirmation_needs_triage.deliver_later
    else
      mailer.confirmation.deliver_later
      TextDeliveryJob.perform_later(:consent_given, consent_form:)
    end
  end
end
