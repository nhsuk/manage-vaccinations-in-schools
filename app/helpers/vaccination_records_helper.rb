# frozen_string_literal: true

module VaccinationRecordsHelper
  SYNC_STATUS_COLOURS = {
    synced: "green",
    pending: "blue",
    failed: "red",
    cannot_sync: "orange",
    not_synced: "grey"
  }.freeze

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

  def vaccination_record_sync_status_tag(vaccination_record)
    status = vaccination_record.sync_status
    text = VaccinationRecord.human_enum_name(:sync_statuses, status)

    colour = SYNC_STATUS_COLOURS.fetch(status)

    govuk_tag(text:, colour:)
  end
end
