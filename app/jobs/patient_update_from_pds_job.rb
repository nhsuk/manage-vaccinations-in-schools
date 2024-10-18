# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include NHSAPIConcurrencyConcern
  include MergePatientsConcern

  queue_as :imports

  def perform(patient)
    raise MissingNHSNumber if patient.nhs_number.nil?

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
  end

  class MissingNHSNumber < StandardError
  end
end
