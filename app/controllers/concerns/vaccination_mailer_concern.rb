# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_mail(vaccination_record)
    consent =
      vaccination_record
        .patient_session
        .patient
        .consents
        .order(:created_at)
        .last
    return if consent.route == "self_consent"

    mailer = VaccinationMailer.with(consent:, vaccination_record:)

    if vaccination_record.administered?
      mailer.hpv_vaccination_has_taken_place.deliver_later
    else
      mailer.hpv_vaccination_has_not_taken_place.deliver_later
    end
  end
end
