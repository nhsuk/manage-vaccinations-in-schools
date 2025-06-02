# frozen_string_literal: true

module UserFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir_practitioner
      FHIR::Practitioner.new(
        id: fhir_id,
        name: [FHIR::HumanName.new(family: family_name, given: given_name)]
      )
    end

    def fhir_id
      "User/#{id}"
    end
  end
end
