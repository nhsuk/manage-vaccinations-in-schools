# frozen_string_literal: true

module LocationFHIRConcern
  extend ActiveSupport::Concern

  class UnknownValueError < StandardError
  end

  def fhir_reference
    if school?
      value = urn || "X9999"
      system = "https://fhir.hl7.org.uk/Id/urn-school-number"
    elsif clinic?
      value = ods_code || "X9999"
      system = "https://fhir.nhs.uk/Id/ods-organization-code"
    else
      raise UnknownValueError, "Unsupported location type: #{type}"
    end

    FHIR::Reference.new(identifier: FHIR::Identifier.new(value:, system:))
  end
end
