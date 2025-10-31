# frozen_string_literal: true

class InvalidateSelfConsentsJob < ApplicationJob
  queue_as :consents

  def perform
    academic_year = AcademicYear.current

    Programme.find_each do |programme|
      patients =
        Patient.has_vaccination_status(
          %i[not_eligible eligible due],
          programme:,
          academic_year:
        )

      Team.find_each do |team|
        consents =
          Consent
            .via_self_consent
            .where(academic_year:, team:, programme:)
            .where(patient: patients)
            .where("created_at < ?", Date.current.beginning_of_day)
            .not_withdrawn

        triages =
          Triage
            .where(academic_year:, team:, programme:)
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
