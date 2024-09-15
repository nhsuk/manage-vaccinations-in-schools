# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_mail(vaccination_record)
    patient_session = vaccination_record.patient_session

    action_name =
      if vaccination_record.administered?
        :hpv_vaccination_has_taken_place
      else
        :hpv_vaccination_has_not_taken_place
      end

    patient_session.consents_to_send_communication.each do |consent|
      VaccinationMailer
        .with(consent:, vaccination_record:)
        .public_send(action_name)
        .deliver_later
    end
  end
end
