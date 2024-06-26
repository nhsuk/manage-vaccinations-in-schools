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

    if vaccination_record.administered?
      VaccinationMailer.hpv_vaccination_has_taken_place(
        vaccination_record:
      ).deliver_later
    else
      VaccinationMailer.hpv_vaccination_has_not_taken_place(
        vaccination_record:
      ).deliver_later
    end
  end
end
