# frozen_string_literal: true

class PatientNHSNumberLookupJob < ApplicationJob
  def self.concurrent_jobs_per_second = 5
  def self.concurrency_key = :pds

  include NHSAPIConcurrencyConcernGoodJob

  queue_as :imports

  def perform(patient)
    return if patient.nhs_number.present? && !patient.invalidated?

    pds_patient =
      PDS::Patient.search(
        family_name: patient.family_name,
        given_name: patient.given_name,
        date_of_birth: patient.date_of_birth,
        address_postcode: patient.address_postcode
      )

    return if pds_patient.nil?

    if (
         existing_patient =
           Patient
             .where.not(id: patient.id)
             .find_by(nhs_number: pds_patient.nhs_number)
       )
      PatientMerger.call(to_keep: existing_patient, to_destroy: patient)
      existing_patient.update_from_pds!(pds_patient)
    else
      patient.nhs_number = pds_patient.nhs_number
      patient.update_from_pds!(pds_patient)
    end
  end
end
