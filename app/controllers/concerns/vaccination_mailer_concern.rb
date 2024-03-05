module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_mail(vaccination_record)
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
