# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include NHSAPIConcurrencyConcern
  include MergePatientsConcern

  queue_as :pds

  discard_on NHS::PDS::InvalidNHSNumber
  discard_on NHS::PDS::PatientNotFound

  def perform(patient)
    raise MissingNHSNumber if patient.nhs_number.nil?

    return if patient.invalidated?

    pds_patient = PDS::Patient.find(patient.nhs_number)

    if pds_patient.nhs_number != patient.nhs_number
      if (
           existing_patient =
             Patient.includes(
               :class_imports,
               :cohort_imports,
               :immunisation_imports,
               :patient_sessions
             ).find_by(nhs_number: pds_patient.nhs_number)
         )
        merge_patients!(existing_patient, patient)
        existing_patient.update_from_pds!(pds_patient)
      else
        patient.nhs_number = pds_patient.nhs_number
        patient.update_from_pds!(pds_patient)
      end
    else
      patient.update_from_pds!(pds_patient)
    end
  rescue NHS::PDS::InvalidatedResource
    patient.invalidate!
  end

  class MissingNHSNumber < StandardError
  end
end
