# frozen_string_literal: true

module OrganisationFHIRConcern
  extend ActiveSupport::Concern

  class_methods do
    def fhir_reference(ods_code:)
      FHIR::Reference.new(
        type: "Organization",
        identifier:
          FHIR::Identifier.new(
            system: "https://fhir.nhs.uk/Id/ods-organization-code",
            value: ods_code
          )
      )
    end
  end
end
