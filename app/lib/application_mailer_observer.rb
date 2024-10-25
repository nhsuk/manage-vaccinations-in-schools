# frozen_string_literal: true

class ApplicationMailerObserver
  def self.delivered_email(message)
    consent_form_id = message.consent_form_id
    patient_id = message.patient_id
    template_id = message.template_id

    message.to.map do |recipient|
      NotifyLogEntry.create!(
        type: :email,
        template_id:,
        recipient:,
        patient_id:,
        consent_form_id:
      )
    end
  end
end

ActionMailer::Base.register_observer(ApplicationMailerObserver)
