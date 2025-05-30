# frozen_string_literal: true

# https://www.hl7.org/fhir/immunization.html
module VaccinationRecordFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir
      immunisation = FHIR::Immunization.new

      if performed_by_user.present?
        immunisation.contained << performed_by_user.to_fhir_practitioner
      end

      immunisation.contained << patient.to_fhir

      immunisation.extension = [fhir_vaccination_procedure_extension]
      immunisation.identifier = [fhir_identifier]

      immunisation.status = fhir_status
      immunisation.vaccineCode = fhir_vaccine_code

      immunisation.patient = FHIR::Reference.new(reference: patient.fhir_id)
      immunisation.occurrenceDateTime = performed_at.iso8601
      immunisation.recorded = created_at.iso8601
      immunisation.primarySource = recorded_in_service?
      immunisation.manufacturer =
        FHIR::Reference.new(display: "AstraZeneca Ltd")

      immunisation.location =
        FHIR::Reference.new(
          identifier:
            FHIR::Identifier.new(
              value: "X99999",
              system: "https://fhir.nhs.uk/Id/ods-organization-code"
            )
        )

      immunisation.lotNumber = "4120Z001"
      immunisation.expirationDate = "2021-07-02"

      immunisation.site =
        FHIR::CodeableConcept.new(
          coding: [
            FHIR::Coding.new(
              system: "http://snomed.info/sct",
              code: "368208006",
              display: "Left upper arm structure (body structure)"
            )
          ]
        )

      immunisation.route =
        FHIR::CodeableConcept.new(
          coding: [
            FHIR::Coding.new(
              system: "http://snomed.info/sct",
              code: "78421000",
              display: "Intramuscular route (qualifier value)"
            )
          ]
        )

      immunisation.doseQuantity =
        FHIR::Quantity.new(
          value: 0.5,
          unit: "milliliter",
          system: "http://unitsofmeasure.org",
          code: "ml"
        )

      immunisation.performer = [
        FHIR::Immunization::Performer.new(
          actor: FHIR::Reference.new(reference: performed_by_user.fhir_id)
        ),
        FHIR::Immunization::Performer.new(
          actor: Organisation.fhir_reference(ods_code: performed_ods_code)
        )
      ]

      immunisation.reasonCode = [
        FHIR::CodeableConcept.new(
          coding: [
            FHIR::Coding.new(
              code: "443684005",
              system: "http://snomed.info/sct"
            )
          ]
        )
      ]

      immunisation.protocolApplied = [
        FHIR::Immunization::ProtocolApplied.new(
          targetDisease: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "840539006",
                  display:
                    "Disease caused by severe acute respiratory syndrome coronavirus 2 (disorder)"
                )
              ]
            )
          ],
          doseNumberPositiveInt: 1
        )
      ]

      immunisation
    end

    private

    def fhir_identifier
      FHIR::Identifier.new(
        system:
          "http://manage-vaccinations-in-schools.nhs.uk/vaccination_records",
        value: uuid
      )
    end

    def fhir_vaccination_procedure_extension
      FHIR::Extension.new(
        url:
          "https://fhir.hl7.org.uk/StructureDefinition/Extension-UKCore-VaccinationProcedure",
        valueCodeableConcept:
          FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://snomed.info/sct",
                code: "1324681000000101",
                display:
                  "Administration of first dose of severe acute" \
                    " respiratory syndrome coronavirus 2 vaccine (procedure)"
              )
            ]
          )
      )
    end

    def fhir_status
      case outcome
      when "administered"
        "completed"
      when "refused", "not_well", "contraindications", "already_had",
           "absent_from_school", "absent_from_session"
        "not-done"
      else
        raise ArgumentError, "Unknown outcome: #{outcome}"
      end
    end

    def fhir_vaccine_code
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: vaccine.snomed_product_code,
            display: vaccine.snomed_product_term
          )
        ]
      )
    end
  end
end
