# frozen_string_literal: true

class InvalidateSelfConsentsJob < ApplicationJob
  queue_as :consents

  def perform
    patients =
      Patient.preload(:triages, :vaccination_records, consents: :parent)

    Programme.find_each do |programme|
      unvaccinated_patient_ids =
        patients
          .reject { it.programme_outcome.vaccinated?(programme) }
          .map(&:id)

      Organisation.find_each do |organisation|
        consents =
          Consent
            .via_self_consent
            .where(organisation:, programme:)
            .where(patient_id: unvaccinated_patient_ids)
            .where("created_at < ?", Date.current.beginning_of_day)
            .not_withdrawn

        triages =
          Triage
            .where(organisation:, programme:)
            .where(patient_id: consents.pluck(:patient_id))
            .where("created_at < ?", Date.current.beginning_of_day)

        ActiveRecord::Base.transaction do
          consents.invalidate_all
          triages.invalidate_all
        end
      end
    end
  end
end
