# frozen_string_literal: true

module VaccinationRecordFHIRConcern
  extend ActiveSupport::Concern

  included do
    def to_fhir
      # Create contained Practitioner
      practitioner = FHIR::Practitioner.new
      practitioner.id = "Pract1"
      practitioner.name = [
        FHIR::HumanName.new(family: "Nightingale", given: ["Florence"])
      ]

      # Create contained Patient
      fhir_patient = FHIR::Patient.new
      fhir_patient.id = "Pat1"
      fhir_patient.identifier = [
        FHIR::Identifier.new(
          system: "https://fhir.nhs.uk/Id/nhs-number",
          value: "9449310475"
        )
      ]
      fhir_patient.name = [
        FHIR::HumanName.new(family: "Taylor", given: ["Sarah"])
      ]
      fhir_patient.gender = "unknown"
      fhir_patient.birthDate = "1965-02-28"
      fhir_patient.address = [FHIR::Address.new(postalCode: "EC1A 1BB")]

      # Create Immunization
      immunisation = FHIR::Immunization.new
      immunisation.contained = [practitioner, fhir_patient]

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
                    "Administration of first dose of severe acute respiratory syndrome coronavirus 2 vaccine (procedure)"
                )
              ]
            )
        )
      ]

      # Add identifier
      immunisation.identifier = [
        FHIR::Identifier.new(
          system: "https://supplierABC/identifiers/vacc",
          value: "a7437179-e86e-4855-b68e-24b5jhg3g"
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
                "COVID-19 Vaccine Vaxzevria (ChAdOx1 S [recombinant]) not less than 2.5x100,000,000 infectious units/0.5ml dose suspension for injection multidose vials (AstraZeneca UK Ltd) (product)"
            )
          ]
        )

      immunisation.patient = FHIR::Reference.new(reference: "#Pat1")
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
          actor: FHIR::Reference.new(reference: "#Pract1")
        ),
        FHIR::Immunization::Performer.new(
          actor:
            FHIR::Reference.new(
              type: "Organization",
              identifier:
                FHIR::Identifier.new(
                  system: "https://fhir.nhs.uk/Id/ods-organization-code",
                  value: "B0C4P"
                )
            )
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
