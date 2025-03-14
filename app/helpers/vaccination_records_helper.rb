# frozen_string_literal: true

module VaccinationRecordsHelper
  def vaccination_record_location(vaccination_record)
    if (location = vaccination_record.location)
      if location.generic_clinic?
        vaccination_record.location_name
      elsif vaccination_record.already_had?
        "Unknown"
      else
        location.name
      end
    else
      vaccination_record.location_name
    end
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
end
