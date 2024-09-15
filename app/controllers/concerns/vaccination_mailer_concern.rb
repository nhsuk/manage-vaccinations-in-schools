# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    patient_session = vaccination_record.patient_session

    mailer_action =
      if vaccination_record.administered?
        :hpv_vaccination_has_taken_place
      else
        :hpv_vaccination_has_not_taken_place
      end

    text_template_name =
      if vaccination_record.administered?
        :vaccination_has_taken_place
      else
        :vaccination_didnt_happen
      end

    patient_session.consents_to_send_communication.each do |consent|
      params = { consent:, vaccination_record: }

      VaccinationMailer.with(params).public_send(mailer_action).deliver_later

      TextDeliveryJob.perform_later(text_template_name, **params)
    end
  end
end
