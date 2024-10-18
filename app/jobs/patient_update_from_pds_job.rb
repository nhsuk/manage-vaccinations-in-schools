# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include NHSAPIConcurrencyConcern

  queue_as :imports

  def perform(patient)
    raise MissingNHSNumber if patient.nhs_number.nil?

    pds_patient = PDS::Patient.find(patient.nhs_number)
    patient.update_from_pds!(pds_patient)
  end

  class MissingNHSNumber < StandardError
  end
end
