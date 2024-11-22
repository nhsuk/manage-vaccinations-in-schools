# frozen_string_literal: true

class PatientNHSNumberLookupJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :imports

  def perform(patient)
    return if patient.nhs_number.present?

    pds_patient =
      PDS::Patient.search(
        family_name: patient.family_name,
        given_name: patient.given_name,
        date_of_birth: patient.date_of_birth,
        address_postcode: patient.address_postcode
      )

    return if pds_patient.nil?

    if (existing_patient = Patient.find_by(nhs_number: pds_patient.nhs_number))
      PatientMerger.call(to_keep: existing_patient, to_destroy: patient)
      existing_patient.update_from_pds!(pds_patient)
    else
      patient.nhs_number = pds_patient.nhs_number
      patient.update_from_pds!(pds_patient)
    end
  end
end
