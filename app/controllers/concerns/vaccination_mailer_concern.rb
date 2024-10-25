# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    patient_session = vaccination_record.patient_session
    patient = vaccination_record.patient

    return unless patient.send_notifications?

    mailer_action =
      if vaccination_record.administered?
        :confirmation_administered
      else
        :confirmation_not_administered
      end

    text_template_name = :"vaccination_#{mailer_action}"

    patient_session.consents_to_send_communication.each do |consent|
      params = { consent:, vaccination_record: }

      VaccinationMailer.with(params).public_send(mailer_action).deliver_later

      TextDeliveryJob.perform_later(text_template_name, **params)
    end
  end
end
