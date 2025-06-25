# frozen_string_literal: true

module FHIRMapper
  class Vaccine
    delegate_missing_to :@vaccine

    def initialize(vaccine)
      @vaccine = vaccine
    end

    def fhir_codeable_concept
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: snomed_product_code,
            display: snomed_product_term
          )
        ]
      )
    end

    def fhir_manufacturer_reference
      FHIR::Reference.new(display: manufacturer)
    end
  end
end
