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
end
