# frozen_string_literal: true

module FHIRMapper
  class VaccinationRecord
    delegate_missing_to :@vaccination_record

    def initialize(vaccination_record)
      @vaccination_record = vaccination_record
    end

    def fhir_record
      immunisation = FHIR::Immunization.new(id: nhs_immunisations_api_id)

      if performed_by_user.present?
        immunisation.contained << performed_by_user.fhir_practitioner(
          reference_id: "Practitioner1"
        )
      end

      immunisation.contained << patient.fhir_record(reference_id: "Patient1")

      immunisation.extension = [fhir_vaccination_procedure_extension]
      immunisation.identifier = [fhir_identifier]

      immunisation.status = fhir_status
      immunisation.vaccineCode = vaccine.fhir_codeable_concept

      immunisation.patient = FHIR::Reference.new(reference: "#Patient1")
      immunisation.occurrenceDateTime = performed_at.iso8601(3)
      immunisation.recorded = created_at.iso8601(3)
      immunisation.primarySource = recorded_in_service?
      immunisation.manufacturer = vaccine.fhir_manufacturer_reference

      immunisation.location = (location || ::Location.school.new).fhir_reference
      immunisation.lotNumber = batch.name
      immunisation.expirationDate = batch.expiry.to_s
      immunisation.site = fhir_site
      immunisation.route = fhir_route
      immunisation.doseQuantity = fhir_dose_quantity
      immunisation.performer = [
        fhir_user_performer(reference_id: "Practitioner1"),
        fhir_org_performer
      ]
      immunisation.reasonCode = [fhir_reason_code]
      immunisation.protocolApplied = [fhir_protocol_applied]

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
        valueCodeableConcept: vaccine.fhir_procedure_coding(dose_sequence:)
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

    def fhir_site
      site_info =
        ::VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[delivery_site]

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
            code: delivery_method_snomed_code,
            display: delivery_method_snomed_term
          )
        ]
      )
    end

    def fhir_dose_quantity
      FHIR::Quantity.new(
        value: dose_volume_ml.to_f,
        unit: "ml",
        system: "http://snomed.info/sct",
        code: "258773002"
      )
    end

    def fhir_user_performer(reference_id:)
      FHIR::Immunization::Performer.new(
        actor: FHIR::Reference.new(reference: "##{reference_id}")
      )
    end

    def fhir_org_performer
      FHIR::Immunization::Performer.new(
        actor: Team.fhir_reference(ods_code: performed_ods_code)
      )
    end

    def fhir_reason_code
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(code: "723620004", system: "http://snomed.info/sct")
        ]
      )
    end

    def fhir_protocol_applied
      FHIR::Immunization::ProtocolApplied.new(
        targetDisease: [programme.fhir_target_disease_coding],
        doseNumberPositiveInt: dose_sequence
      )
    end
  end
end
