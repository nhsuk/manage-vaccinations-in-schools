# frozen_string_literal: true

module VaccinationRecordSyncToNHSImmunisationsAPIConcern
  extend ActiveSupport::Concern

  included do
    scope :syncable_to_nhs_immunisations_api,
          -> do
            includes(:patient, :programme).where(
              notify_parents: true
            ).recorded_in_service
          end
  end

  def syncable_to_nhs_immunisations_api?
    recorded_in_service? && notify_parents
  end

  def sync_status
    should_be_synced =
      NHS::ImmunisationsAPI.should_be_in_immunisations_api?(
        self,
        ignore_nhs_number: true
      )
    return :not_synced unless should_be_synced

    return :cannot_sync if patient.nhs_number.blank?

    synced_at = nhs_immunisations_api_synced_at
    pending_at = nhs_immunisations_api_sync_pending_at
    if synced_at.present? && (pending_at.nil? || synced_at > pending_at)
      return :synced
    end

    return :failed if pending_at.present? && 24.hours.ago > pending_at

    :pending
  end

  def sync_to_nhs_immunisations_api
    return unless Flipper.enabled?(:enqueue_sync_vaccination_records_to_nhs)
    return unless syncable_to_nhs_immunisations_api?

    # The immunisations api module checks if a sync is still pending using this
    # timestamp.
    update!(nhs_immunisations_api_sync_pending_at: Time.current)
    SyncVaccinationRecordToNHSJob.perform_later(self)
  end
end
