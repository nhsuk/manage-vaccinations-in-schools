# frozen_string_literal: true

class InvalidateSelfConsentsJob < ApplicationJob
  queue_as :consents

  def perform
    programmes = Programme.all
    academic_year = AcademicYear.current

    programmes.each do |programme|
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
            .where_programme(programme)
            .where(academic_year:, team:, patient: patients)
            .where("created_at < ?", Date.current.beginning_of_day)
            .not_withdrawn

        triages =
          Triage
            .where_programme(programme)
            .where(
              academic_year:,
              team:,
              patient_id: consents.pluck(:patient_id)
            )
            .where("created_at < ?", Date.current.beginning_of_day)

        ActiveRecord::Base.transaction do
          consents.invalidate_all
          triages.safe_to_invalidate_automatically.invalidate_all
        end
      end
    end
  end
end
