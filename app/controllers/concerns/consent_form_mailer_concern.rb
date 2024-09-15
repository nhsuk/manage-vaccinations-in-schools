# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_record_mail(consent_form)
    mailer = ConsentMailer.with(consent_form:)

    if consent_form.contact_injection?
      mailer.confirmation_injection.deliver_later
    elsif consent_form.consent_refused?
      mailer.confirmation_refused.deliver_later
    elsif consent_form.needs_triage?
      mailer.confirmation_needs_triage.deliver_later
    else
      mailer.confirmation.deliver_later
    end

    mailer.give_feedback.deliver_later(wait: 1.hour)
  end
end
