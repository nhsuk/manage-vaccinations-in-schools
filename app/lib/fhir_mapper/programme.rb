# frozen_string_literal: true

module FHIRMapper
  class Programme
    delegate :snomed_target_disease_codes,
             :snomed_target_disease_terms,
             to: :@programme

    def initialize(programme)
      @programme = programme
    end

    def fhir_target_disease_coding
      snomed_target_disease_codes
        .zip(snomed_target_disease_terms)
        .map do
          FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://snomed.info/sct",
                code: it.first,
                display: it.second
              )
            ]
          )
        end
    end

    def self.from_fhir_record(fhir_record)
      target_diseases = fhir_record.protocolApplied.sole.targetDisease
      target_disease_codes =
        target_diseases.map do |disease|
          disease
            .coding
            .find { |coding| coding.system == "http://snomed.info/sct" }
            .code
        end

      ::Programme.find_by_snomed_target_disease_codes(target_disease_codes)
    end
  end
end
