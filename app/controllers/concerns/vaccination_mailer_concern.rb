# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    patient_session = vaccination_record.patient_session
    patient = vaccination_record.patient

    return unless patient.send_notifications?

    sent_by = current_user

    mailer_action =
      if vaccination_record.administered?
        :confirmation_administered
      else
        :confirmation_not_administered
      end

    text_template_name = :"vaccination_#{mailer_action}"

    parents =
      patient_session
        .latest_consents
        .select(&:response_given?)
        .filter_map(&:parent)
        .select(&:contactable?)

    parents.each do |parent|
      params = { parent:, patient:, vaccination_record:, sent_by: }

      if parent.email.present?
        VaccinationMailer.with(params).public_send(mailer_action).deliver_later
      end

      TextDeliveryJob.perform_later(text_template_name, **params)
    end
  end
end
