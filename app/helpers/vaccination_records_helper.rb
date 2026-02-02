# frozen_string_literal: true

module VaccinationRecordsHelper
  def vaccination_record_location(vaccination_record)
    vaccination_record.location_name.presence ||
      vaccination_record.location&.name || "Unknown"
  end

  def vaccination_record_status_tag(vaccination_record)
    text = vaccination_record.human_enum_name(:outcome)

    colour =
      if vaccination_record.administered? || vaccination_record.already_had?
        "green"
      else
        "red"
      end

    govuk_tag(text:, colour:)
  end

  def vaccination_record_source(vaccination_record)
    if vaccination_record.sourced_from_national_reporting?
      "Mavis national reporting upload"
    else
      vaccination_record.human_enum_name(:source)
    end
  end

  def already_vaccinated_link_label(session:, patient:, programme:)
    if programme.mmr?
      if had_first_dose?(session:, patient:, programme:)
        "Record 2nd dose as already given"
      else
        "Record 1st dose as already given"
      end
    else
      "Record as already vaccinated"
    end
  end

  private

  def had_first_dose?(session:, patient:, programme:)
    programme_status =
      patient.programme_status(programme, academic_year: session.academic_year)
    programme_status.dose_sequence.present? &&
      programme_status.dose_sequence > 1
  end
end
