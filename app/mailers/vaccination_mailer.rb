class VaccinationMailer < ApplicationMailer
  def hpv_vaccination_has_taken_place(vaccination_record:)
    template_mail(
      EMAIL_TEMPLATES[:confirmation_the_hpv_vaccination_has_taken_place],
      **opts(vaccination_record)
    )
  end

  private

  def consent
    @patient_session.patient.consents.order(:created_at).last
  end

  def to
    consent.parent_email
  end

  def parent_name
    consent.parent_name
  end

  def opts(vaccination_record)
    @vaccination_record = vaccination_record
    @patient_session = vaccination_record.patient_session
    @session = vaccination_record.patient_session.session
    @patient = vaccination_record.patient_session.patient

    { to:, reply_to_id:, personalisation: vaccination_personalisation }
  end

  def vaccination_personalisation
    personalisation.merge(
      batch_name:,
      day_month_year_of_vaccination:,
      today_or_date_of_vaccination:
    )
  end

  def today_or_date_of_vaccination
    if @vaccination_record.recorded_at.today?
      "today"
    else
      @vaccination_record.recorded_at.to_fs(:nhsuk_date_short_month)
    end
  end

  def batch_name
    @vaccination_record.batch.name
  end

  def day_month_year_of_vaccination
    @vaccination_record.recorded_at.strftime("%d/%m/%Y")
  end
end
