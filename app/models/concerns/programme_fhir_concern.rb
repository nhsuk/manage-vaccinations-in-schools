#frozen_string_literal: true

module ProgrammeFHIRConcern
  extend ActiveSupport::Concern

  included do
    def fhir_target_disease_coding
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: snomed_target_disease_code,
            display: snomed_target_disease_term
          )
        ]
      )
    end
  end
end
