# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_consent_form_confirmation(consent_form)
    if consent_form.contact_injection?
      EmailDeliveryJob.perform_later(
        :consent_confirmation_injection,
        consent_form:
      )
    elsif consent_form.consent_refused?
      EmailDeliveryJob.perform_later(
        :consent_confirmation_refused,
        consent_form:
      )

      if consent_form.parent_phone_receive_updates
        SMSDeliveryJob.perform_later(
          :consent_confirmation_refused,
          consent_form:
        )
      end
    elsif consent_form.needs_triage?
      EmailDeliveryJob.perform_later(
        :consent_confirmation_triage,
        consent_form:
      )
    elsif consent_form.actual_upcoming_session.clinic? ||
          consent_form.actual_upcoming_session.completed?
      EmailDeliveryJob.perform_later(
        :consent_confirmation_clinic,
        consent_form:
      )
    else
      EmailDeliveryJob.perform_later(:consent_confirmation_given, consent_form:)

      if consent_form.parent_phone_receive_updates
        SMSDeliveryJob.perform_later(:consent_confirmation_given, consent_form:)
      end
    end
  end
end
