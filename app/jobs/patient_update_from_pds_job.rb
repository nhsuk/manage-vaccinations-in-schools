# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :pds

  discard_on NHS::PDS::PatientNotFound

  def perform(patient)
    raise MissingNHSNumber if patient.nhs_number.nil?

    return if patient.invalidated?

    pds_patient = PDS::Patient.find(patient.nhs_number)

    if pds_patient.nhs_number != patient.nhs_number
      if (
           existing_patient =
             Patient.find_by(nhs_number: pds_patient.nhs_number)
         )
        PatientMerger.call(to_keep: existing_patient, to_destroy: patient)
        existing_patient.update_from_pds!(pds_patient)
      else
        patient.nhs_number = pds_patient.nhs_number
        patient.update_from_pds!(pds_patient)
      end
    else
      patient.update_from_pds!(pds_patient)
    end
  rescue NHS::PDS::InvalidatedResource, NHS::PDS::InvalidNHSNumber
    patient.invalidate!
    PatientNHSNumberLookupJob.perform_later(patient)
  end

  class MissingNHSNumber < StandardError
  end
end
