# frozen_string_literal: true

module UserFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir_practitioner(reference_id: nil)
      FHIR::Practitioner.new(
        id: reference_id,
        name: [FHIR::HumanName.new(family: family_name, given: given_name)]
      )
    end
  end
end
