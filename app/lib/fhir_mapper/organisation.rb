# frozen_string_literal: true

module FHIRMapper
  class Organisation
    def initialize(organisation)
      @organisation = organisation
    end

    def self.fhir_reference(ods_code:)
      FHIR::Reference.new(
        type: "Organization",
        identifier:
          FHIR::Identifier.new(
            system: "https://fhir.nhs.uk/Id/ods-organization-code",
            value: ods_code
          )
      )
    end

    def fhir_reference = self.class.fhir_reference(ods_code:)

    delegate :ods_code, to: :@organisation
  end
end
