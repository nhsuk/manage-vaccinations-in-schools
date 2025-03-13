# frozen_string_literal: true

class InvalidateSelfConsentsJob < ApplicationJob
  queue_as :consents

  def perform
    Programme.find_each do |programme|
      patients =
        Patient.has_vaccination_status(
          %i[none_yet could_not_vaccinate],
          programme:
        )

      Organisation.find_each do |organisation|
        consents =
          Consent
            .via_self_consent
            .where(organisation:, programme:)
            .where(patient: patients)
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
