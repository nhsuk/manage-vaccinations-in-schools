# frozen_string_literal: true

class VaccinationMailer < ApplicationMailer
  def hpv_vaccination_has_taken_place(vaccination_record:)
    app_template_mail(
      :confirmation_the_hpv_vaccination_has_taken_place,
      vaccination_record
    )
  end

  def hpv_vaccination_has_not_taken_place(vaccination_record:)
    app_template_mail(
      :confirmation_the_hpv_vaccination_didnt_happen,
      vaccination_record
    )
  end

  private

  def opts(vaccination_record)
    @vaccination_record = vaccination_record
    @patient_session = vaccination_record.patient_session
    @consent =
      @patient_session.patient.consents.recorded.order(:created_at).last

    super(@patient_session.session, @patient_session.patient, @consent.parent)
  end

  def personalisation
    super.merge(
      batch_name:,
      day_month_year_of_vaccination:,
      reason_did_not_vaccinate:,
      show_additional_instructions:,
      today_or_date_of_vaccination:
    )
  end

  def today_or_date_of_vaccination
    if @vaccination_record.recorded_at.today?
      "today"
    else
      @vaccination_record.recorded_at.to_date.to_fs(:long)
    end
  end

  def batch_name
    @vaccination_record.batch&.name
  end

  def day_month_year_of_vaccination
    @vaccination_record.recorded_at.to_date.to_fs(:uk_short)
  end

  def reason_did_not_vaccinate
    return if @vaccination_record.administered?

    reason = @vaccination_record.reason
    I18n.t(
      "mailers.vaccination_mailer.reasons_did_not_vaccinate.#{reason}",
      short_patient_name:
    )
  end

  def show_additional_instructions
    @vaccination_record.already_had? ? "no" : "yes"
  end
end
