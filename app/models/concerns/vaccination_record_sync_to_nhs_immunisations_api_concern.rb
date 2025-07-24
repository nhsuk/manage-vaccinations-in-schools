# frozen_string_literal: true

module VaccinationRecordSyncToNHSImmunisationsAPIConcern
  extend ActiveSupport::Concern

  included do
    scope :syncable_to_nhs_immunisations_api,
          -> { includes(:patient).recorded_in_service }
  end

  def syncable_to_nhs_immunisations_api?
    recorded_in_service?
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
