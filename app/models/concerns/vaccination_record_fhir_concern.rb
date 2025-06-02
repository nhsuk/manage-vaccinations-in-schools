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
      immunisation.vaccineCode = vaccine.fhir_codeable_concept

      immunisation.patient = FHIR::Reference.new(reference: patient.fhir_id)
      immunisation.occurrenceDateTime = performed_at.iso8601
      immunisation.recorded = created_at.iso8601
      immunisation.primarySource = recorded_in_service?
      immunisation.manufacturer = vaccine.fhir_manufacturer_reference

      immunisation.location = (location || Location.school.new).fhir_reference
      immunisation.lotNumber = "4120Z001"
      immunisation.expirationDate = "2021-07-02"
      immunisation.site = fhir_site
      immunisation.route = fhir_route
      immunisation.doseQuantity = fhir_dose_quantity
      immunisation.performer = [fhir_user_performer, fhir_org_performer]
      immunisation.reasonCode = [fhir_reason_code]

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

    def fhir_site
      site_info =
        VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[delivery_site]

      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: site_info.first,
            display: site_info.last
          )
        ]
      )
    end

    def fhir_route
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: "78421000",
            display: "Intramuscular route (qualifier value)"
          )
        ]
      )
    end

    def fhir_dose_quantity
      FHIR::Quantity.new(
        value: dose_volume_ml,
        unit: "milliliter",
        system: "http://unitsofmeasure.org",
        code: "ml"
      )
    end

    def fhir_user_performer
      FHIR::Immunization::Performer.new(
        actor: FHIR::Reference.new(reference: performed_by_user.fhir_id)
      )
    end

    def fhir_org_performer
      FHIR::Immunization::Performer.new(
        actor: Organisation.fhir_reference(ods_code: performed_ods_code)
      )
    end

    def fhir_reason_code
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            code: "999004501000000104",
            system: "http://snomed.info/sct"
          )
        ]
      )
    end
  end
end
