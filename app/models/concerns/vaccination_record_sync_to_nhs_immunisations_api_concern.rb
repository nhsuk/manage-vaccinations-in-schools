# frozen_string_literal: true

module VaccinationRecordSyncToNHSImmunisationsAPIConcern
  extend ActiveSupport::Concern

  included do
    scope :syncable_to_nhs_immunisations_api,
          -> { includes(:patient, :programme).recorded_in_service }

    scope :sync_all_to_nhs_immunisations_api,
          -> do
            syncable_to_nhs_immunisations_api.find_each(
              &:sync_to_nhs_immunisations_api
            )
          end
  end

  def syncable_to_nhs_immunisations_api? = recorded_in_service?

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
    return unless Flipper.enabled?(:imms_api_sync_job)
    return unless syncable_to_nhs_immunisations_api?

    # The immunisations api module checks if a sync is still pending using this
    # timestamp.
    update!(nhs_immunisations_api_sync_pending_at: Time.current)

    SyncVaccinationRecordToNHSJob.perform_async(id)
  end
end
