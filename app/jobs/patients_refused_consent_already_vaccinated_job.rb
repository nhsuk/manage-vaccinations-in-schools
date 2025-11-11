# frozen_string_literal: true

class PatientsRefusedConsentAlreadyVaccinatedJob < ApplicationJob
  queue_as :patients

  def perform
    return unless should_perform?

    Programme.find_each { |programme| handle_programme!(programme) }
  end

  private

  def academic_year = AcademicYear.current

  def should_perform? = AcademicYear.pending > academic_year

  def handle_programme!(programme)
    programme_type = programme.type

    ActiveRecord::Base.transaction do
      patients_with_consent_refused(programme).find_each do |patient|
        consents =
          ConsentGrouper.call(patient.consents, programme_type:, academic_year:)

        if should_record_already_vaccinated?(consents:)
          record_already_vaccinated!(patient, programme:, consents:)
        end
      end
    end
  end

  def patients_with_consent_refused(programme)
    Patient
      .includes(parent_relationships: :parent)
      .appear_in_programmes([programme], academic_year:)
      .has_vaccination_status(
        %w[not_eligible eligible due],
        programme:,
        academic_year:
      )
      .has_consent_status("refused", programme:, academic_year:)
  end

  def should_record_already_vaccinated?(consents:)
    consents.all?(&:reason_for_refusal_already_vaccinated?)
  end

  def record_already_vaccinated!(patient, programme:, consents:)
    names =
      consents.map { |consent| "#{consent.name} (#{consent.who_responded})" }

    notes = "Self-reported by #{names.to_sentence}"
    performed_at = consents.map(&:submitted_at).min

    VaccinationRecord.create!(
      location_name: "Unknown",
      notes:,
      outcome: "already_had",
      patient:,
      performed_at:,
      programme:,
      source: "consent_refusal"
    )

    StatusUpdater.call(patient:)
  end
end
