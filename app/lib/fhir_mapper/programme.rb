# frozen_string_literal: true

module FHIRMapper
  class Programme
    delegate :snomed_target_disease_codes,
             :snomed_target_disease_terms,
             to: :@programme

    def initialize(programme)
      @programme = programme
    end

    def fhir_target_disease_coding
      snomed_target_disease_codes
        .zip(snomed_target_disease_terms)
        .map do
          FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://snomed.info/sct",
                code: it.first,
                display: it.second
              )
            ]
          )
        end
    end

    def self.from_fhir_record(fhir_record)
      target_diseases = fhir_record.protocolApplied.sole.targetDisease
      target_disease_codes =
        target_diseases.map do |disease|
          disease
            .coding
            .find { |coding| coding.system == "http://snomed.info/sct" }
            .code
        end

      if (
           variant_type =
             ::Programme::Variant::SNOMED_TARGET_DISEASE_CODES.key(
               target_disease_codes.to_set
             )
         )
        # If there is a matching `Programme::Variant`
        # TODO: Make `Programme::Variant` type more generic, so that it can handle any programme type;
        #       remove MMR hardcoding here
        if %w[mmr mmrv].include?(variant_type)
          ::Programme.find(
            "mmr",
            disease_types:
              ::Programme::Variant::SNOMED_TARGET_DISEASE_TERMS.fetch(
                variant_type
              )
          )
        else
          raise Programme::InvalidType,
                "Programme::Variant type not mapped to a Programme; #{variant_type}"
        end
      else
        # Otherwise it must be a `Programme`
        ::Programme.find(
          ::Programme::SNOMED_TARGET_DISEASE_CODES.key(
            target_disease_codes.to_set
          )
        )
      end
    end
  end
end
