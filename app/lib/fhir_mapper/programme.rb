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
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: snomed_target_disease_codes,
            display: snomed_target_disease_terms
          )
        ]
      )
    end
  end
end
