# frozen_string_literal: true

module VaccinationRecordFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir
      immunisation = FHIR::Immunization.new

      if performed_by_user.present?
        immunisation.contained << performed_by_user.to_fhir_practitioner
      end

      immunisation.contained << patient.to_fhir

      # Add extension
      immunisation.extension = [
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
      ]

      immunisation.identifier = [
        FHIR::Identifier.new(
          system:
            "http://manage-vaccinations-in-schools.nhs.uk/vaccination_records",
          value: uuid
        )
      ]

      # Set other properties
      immunisation.status = "completed"
      immunisation.vaccineCode =
        FHIR::CodeableConcept.new(
          coding: [
            FHIR::Coding.new(
              system: "http://snomed.info/sct",
              code: "39114911000001105",
              display:
                "COVID-19 Vaccine Vaxzevria (ChAdOx1 S [recombinant]) not" \
                  " less than 2.5x100,000,000 infectious units/0.5ml dose" \
                  " suspension for injection multidose vials (AstraZeneca UK" \
                  " Ltd) (product)"
            )
          ]
        )

      immunisation.patient = FHIR::Reference.new(reference: patient.fhir_id)
      immunisation.occurrenceDateTime = "2021-02-07T13:28:17.271+00:00"
      immunisation.recorded = "2021-02-07T13:28:17.271+00:00"
      immunisation.primarySource = true
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
  end
end
