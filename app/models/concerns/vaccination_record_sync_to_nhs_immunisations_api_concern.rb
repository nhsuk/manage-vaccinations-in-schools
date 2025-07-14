# frozen_string_literal: true

module VaccinationRecordSyncToNHSImmunisationsAPIConcern
  extend ActiveSupport::Concern

  NHS_IMMUNISATIONS_API_PROGRAMME_TYPES = %w[flu hpv].freeze

  included do
    scope :syncable_to_nhs_immunisations_api,
          -> do
            includes(:programme, :patient)
              .recorded_in_service
              .administered
              .kept
              .where(
              programmes: {
                type: NHS_IMMUNISATIONS_API_PROGRAMME_TYPES
              }
            )
          end
  end

  def syncable_to_nhs_immunisations_api?
    kept? && recorded_in_service? && administered? &&
      programme.type.in?(NHS_IMMUNISATIONS_API_PROGRAMME_TYPES)
  end

  def sync_to_nhs_immunisations_api
    return unless Flipper.enabled?(:sync_vaccination_records_to_nhs_on_create)
    return unless syncable_to_nhs_immunisations_api?

    # TODO: Set nhs_immunisations_api_pending_at
    SyncVaccinationRecordToNHSJob.perform_later(self)
  end
end
