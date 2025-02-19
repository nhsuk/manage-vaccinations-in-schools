# frozen_string_literal: true

class InvalidateSelfConsentsJob < ApplicationJob
  queue_as :consents

  def perform
    organisation_ids = Organisation.pluck(:id)
    programme_ids = Programme.pluck(:id)

    organisation_ids
      .product(programme_ids)
      .each do |organisation_id, programme_id|
        consents =
          Consent
            .via_self_consent
            .where(organisation_id:, programme_id:)
            .where("created_at < ?", Date.current.beginning_of_day)
            .not_withdrawn

        triages =
          Triage
            .where(organisation_id:, programme_id:)
            .where("created_at < ?", Date.current.beginning_of_day)
            .where(patient_id: consents.pluck(:patient_id))

        ActiveRecord::Base.transaction do
          consents.invalidate_all
          triages.invalidate_all
        end
      end
  end
end
