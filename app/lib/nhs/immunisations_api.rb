# frozen_string_literal: true

module NHS::ImmunisationsAPI
  class PatientNotFound < StandardError
  end

  class << self
    def record_immunisation(vaccination_record)
      NHS::API.connection.post(
        "/immunisation-fhir-api/FHIR/R4/Immunization",
        vaccination_record.to_fhir.to_json,
        "Content-Type" => "application/fhir+json"
      )
    end
  end
end
