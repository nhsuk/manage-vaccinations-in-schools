# frozen_string_literal: true

class AppVaccinationRecordAPISyncStatusComponent < ViewComponent::Base
  attr_reader :vaccination_record

  delegate :nhs_immunisations_api_synced_at,
           :sync_status,
           :recorded_in_service?,
           :notify_parents,
           to: :vaccination_record

  SYNC_STATUS_COLOURS = {
    synced: "green",
    pending: "blue",
    failed: "red",
    cannot_sync: "orange",
    not_synced: "grey"
  }.freeze

  def initialize(vaccination_record)
    super
    @vaccination_record = vaccination_record
  end

  def call
    safe_join(
      [
        vaccination_record_sync_status_tag,
        additional_information_text,
        last_synced_at
      ].compact,
      tag.br
    )
  end

  private

  def vaccination_record_sync_status_tag
    text = VaccinationRecord.human_enum_name(:sync_statuses, sync_status)
    colour = SYNC_STATUS_COLOURS.fetch(sync_status)

    govuk_tag(text:, colour:)
  end

  def secondary_text(text)
    return unless text

    tag.span(text, class: "nhsuk-u-secondary-text-colour")
  end

  def additional_information_text
    secondary_text(
      case sync_status
      when :not_synced
        is_not_a_synced_programme =
          !vaccination_record.programme.can_write_to_immunisations_api?
        if is_not_a_synced_programme
          "Records are currently not synced for this programme"
        elsif notify_parents == false
          "The child gave consent under Gillick competence and does not want their parents to be notified. " \
            "You must let the child’s GP know they were vaccinated."
        elsif recorded_in_service?
          "Records are not synced if the vaccination was not given"
        elsif vaccination_record.session.nil?
          "Records are not synced if the vaccination was not recorded in Mavis"
        end
      when :cannot_sync
        "You must add an NHS number to the child's record before this record will sync"
      when :failed
        "The Mavis team is aware of the issue and is working to resolve it"
      end
    )
  end

  def last_synced_at
    if %i[pending synced].include?(sync_status)
      secondary_text(
        "Last synced: #{
          if nhs_immunisations_api_synced_at.present?
            nhs_immunisations_api_synced_at.to_fs(:long)
          else
            "Never"
          end
        }"
      )
    end
  end
end
