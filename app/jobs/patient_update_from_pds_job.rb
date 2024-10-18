# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :patients

  def perform(patient)
    raise MissingNHSNumber if patient.nhs_number.nil?

    pds_patient = NHS::PDS.get_patient(patient.nhs_number).body
    patient.update_from_pds!(pds_patient)
  end

  class MissingNHSNumber < StandardError
  end
end
