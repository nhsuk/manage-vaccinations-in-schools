# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_record_mail(consent_form)
    if consent_form.contact_injection?
      ConsentFormMailer.confirmation_injection(consent_form:).deliver_later
    elsif consent_form.consent_refused?
      ConsentFormMailer.confirmation_refused(consent_form:).deliver_later
    elsif consent_form.needs_triage?
      ConsentFormMailer.confirmation_needs_triage(consent_form:).deliver_later
    else
      ConsentFormMailer.confirmation(consent_form:).deliver_later
    end

    send_feedback_request_mail(consent_form: @consent_form)
  end

  def send_feedback_request_mail(consent_form:)
    ConsentFormMailer.give_feedback(consent_form:).deliver_later(wait: 1.hour)
  end
end
