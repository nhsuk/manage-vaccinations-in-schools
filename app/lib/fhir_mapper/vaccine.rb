# frozen_string_literal: true

module FHIRMapper
  class Vaccine
    delegate :snomed_procedure_code,
             :snomed_procedure_term,
             :snomed_product_code,
             :snomed_product_term,
             :manufacturer,
             to: :@vaccine

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

    def fhir_procedure_coding(dose_sequence:)
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: snomed_procedure_code(dose_sequence:),
            display: snomed_procedure_term
          )
        ]
      )
    end
  end
end
