# frozen_string_literal: true

module VaccinationRecordSyncToNHSImmunisationsAPIConcern
  extend ActiveSupport::Concern

  included do
    scope :syncable_to_nhs_immunisations_api,
          -> { includes(:patient).recorded_in_service }

    scope :sync_all_to_nhs_immunisations_api,
          -> do
            return unless Flipper.enabled?(:imms_api_sync_job)

            ids = syncable_to_nhs_immunisations_api.pluck(:id)

            VaccinationRecord.where(id: ids).update_all(
              nhs_immunisations_api_sync_pending_at: Time.current
            )

            SyncVaccinationRecordToNHSJob.perform_bulk(ids.zip)
          end

    before_save :touch_nhs_immunisations_api_sync_pending_at,
                if: :changes_need_to_be_synced_to_nhs_immunisations_api?
    after_commit :queue_sync_to_nhs_immunisations_api
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

  def changes_need_to_be_synced_to_nhs_immunisations_api?
    changes.present? && !nhs_immunisations_api_etag_changed? &&
      !nhs_immunisations_api_sync_pending_at_changed? &&
      !nhs_immunisations_api_synced_at_changed? &&
      !nhs_immunisations_api_id_changed?
  end

  def touch_nhs_immunisations_api_sync_pending_at
    return unless Flipper.enabled?(:imms_api_sync_job)
    return unless syncable_to_nhs_immunisations_api?

    self.nhs_immunisations_api_sync_pending_at = Time.current
  end

  def queue_sync_to_nhs_immunisations_api
    return unless Flipper.enabled?(:imms_api_sync_job)
    return unless syncable_to_nhs_immunisations_api?
    return if nhs_immunisations_api_sync_pending_at.nil?

    if nhs_immunisations_api_synced_at &&
         (
           nhs_immunisations_api_sync_pending_at <
             nhs_immunisations_api_synced_at
         )
      return
    end

    SyncVaccinationRecordToNHSJob.perform_async(id)
  end

  def sync_to_nhs_immunisations_api!
    touch_nhs_immunisations_api_sync_pending_at
    save!

    # The after_commit callback queues the job to actually perform the sync
    # with the API.
  end
end
