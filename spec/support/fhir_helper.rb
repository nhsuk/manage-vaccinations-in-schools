#!frozen_string_literal: true

module FHIRHelper
  def fhir_immunisation_json
    JSON.parse(
      File.read(Rails.root.join("spec/fixtures/fhir/immunisation.json"))
    )
  end
end
