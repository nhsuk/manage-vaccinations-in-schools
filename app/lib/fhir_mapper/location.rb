# frozen_string_literal: true

module FHIRMapper
  class Location
    delegate :school?, :clinic?, :type, :urn, :ods_code, to: :@location

    def initialize(location)
      @location = location
    end

    class UnknownValueError < StandardError
    end

    def fhir_reference
      if school?
        value = urn || "X99999"
        system = "https://fhir.hl7.org.uk/Id/urn-school-number"
      elsif clinic?
        value = ods_code || "X99999"
        system = "https://fhir.nhs.uk/Id/ods-organization-code"
      else
        raise UnknownValueError, "Unsupported location type: #{type}"
      end

      FHIR::Reference.new(identifier: FHIR::Identifier.new(value:, system:))
    end
  end
end
