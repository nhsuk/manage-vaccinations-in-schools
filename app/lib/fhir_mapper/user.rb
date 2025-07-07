# frozen_string_literal: true

module FHIRMapper
  class User
    delegate :family_name, :given_name, to: :@user

    def initialize(user)
      @user = user
    end

    def fhir_practitioner(reference_id: nil)
      FHIR::Practitioner.new(
        id: reference_id,
        name: [FHIR::HumanName.new(family: family_name, given: given_name)]
      )
    end
  end
end
