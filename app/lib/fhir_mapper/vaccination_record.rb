# frozen_string_literal: true

module FHIRMapper
  class VaccinationRecord
    class UnknownVaccine < StandardError
    end

    delegate_missing_to :@vaccination_record

    MAVIS_SYSTEM_NAME =
      "http://manage-vaccinations-in-schools.nhs.uk/vaccination_records"

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

    def self.from_fhir_record(fhir_record, patient:)
      attrs = {}

      attrs[:source] = "nhs_immunisations_api"

      attrs[:patient] = patient

      attrs[:nhs_immunisations_api_id] = fhir_record.id
      attrs[:nhs_immunisations_api_synced_at] = Time.current

      attrs[:programme] = programme_from_fhir(fhir_record)

      attrs[:performed_at] = Time.zone.parse(fhir_record.occurrenceDateTime)
      attrs[:outcome] = outcome_from_fhir(fhir_record)

      location_system = fhir_record.location.identifier.system
      location_value = fhir_record.location.identifier.value
      unless location_value == "X99999"
        case location_system
        when "https://fhir.hl7.org.uk/Id/urn-school-number"
          attrs[:location] = ::Location.find_by(urn: location_value)
        when "https://fhir.nhs.uk/Id/ods-organization-code"
          attrs[:location] = ::Location.find_by(ods_code: location_value)
        end
      end

      if attrs[:location].nil?
        attrs[:location_name] = fhir_record.location.identifier.value
      end

      # TODO: There is also a `display` field which could be used to identify the origin of the record,
      #       but this is not marked as required on the schema, so is likely to be unreliable
      attrs[:performed_ods_code] = org_performer_ods_code_from_fhir(fhir_record)

      user_performer_name = user_performer_name_from_fhir(fhir_record)
      attrs[:performed_by_given_name] = user_performer_name&.given&.first
      attrs[:performed_by_family_name] = user_performer_name&.family

      attrs[:delivery_method] = delivery_method_from_fhir(fhir_record)
      attrs[:delivery_site] = site_from_fhir(fhir_record)

      attrs[:dose_sequence] = fhir_record
        .protocolApplied
        .first
        .doseNumberPositiveInt

      attrs[:vaccine] = Vaccine.from_fhir_record(fhir_record)

      if attrs[:vaccine]
        attrs[:batch] = batch_from_fhir(fhir_record, vaccine: attrs[:vaccine])
        attrs[:full_dose] = full_dose_from_fhir(
          fhir_record,
          vaccine: attrs[:vaccine]
        )
      else
        attrs[:notes] = vaccine_batch_notes_from_fhir(fhir_record)
        attrs[:full_dose] = true

        Sentry.capture_exception(
          UnknownVaccine.new(fhir_record.vaccineCode.coding.first.code)
        )
      end

      ::VaccinationRecord.new(attrs)
    end

    private

    def fhir_identifier
      FHIR::Identifier.new(system: MAVIS_SYSTEM_NAME, value: uuid)
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

    private_class_method def self.outcome_from_fhir(fhir_record)
      case fhir_record.status
      when "completed"
        "administered"
      when "not-done"
        # TODO: handle this more gracefully
        raise "Cannot import not-done vaccination records"
      else
        raise "Unexpected vaccination status: #{fhir_record.status}. Expected only 'completed' or 'not-done'"
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

    private_class_method def self.site_from_fhir(fhir_record)
      site_code =
        fhir_record
          .site
          &.coding
          &.find { it.system == "http://snomed.info/sct" }
          &.code
      ::VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS
        .find { |_key, value| value.first == site_code }
        &.first
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

    private_class_method def self.delivery_method_from_fhir(fhir_record)
      route_code =
        fhir_record
          .route
          &.coding
          &.find { it.system == "http://snomed.info/sct" }
          &.code
      ::VaccinationRecord::DELIVERY_METHOD_SNOMED_CODES_AND_TERMS
        .find { |_key, value| value.first == route_code }
        &.first
    end

    def fhir_dose_quantity
      FHIR::Quantity.new(
        value: dose_volume_ml.to_f,
        unit: "ml",
        system: "http://snomed.info/sct",
        code: "258773002"
      )
    end

    private_class_method def self.dose_volume_ml_from_fhir(fhir_record)
      dq = fhir_record.doseQuantity
      if dq.system == "http://unitsofmeasure.org" && dq.code == "ml"
        dq.value.to_f
      else
        raise "Unknown dose quantity system: #{dq.system} and code: #{dq.code}"
      end
    end

    private_class_method def self.full_dose_from_fhir(fhir_record, vaccine:)
      if vaccine.programme.type == :flu && vaccine.method == :nasal
        fhir_record.doseQuantity.value >= vaccine.dose_volume_ml
      end

      true
    end

    private_class_method def self.vaccine_batch_notes_from_fhir(fhir_record)
      fhir_vaccine =
        fhir_record.vaccineCode.coding.find do
          it.system == "http://snomed.info/sct"
        end

      vaccine_snomed_code = fhir_vaccine.code
      vaccine_description = fhir_vaccine.display.presence

      batch_number = fhir_record.lotNumber
      batch_expiry = fhir_record.expirationDate

      "SNOMED product code: #{vaccine_snomed_code}\n" \
        "#{"SNOMED description: #{vaccine_description}\n" if vaccine_description}" \
        "Batch number: #{batch_number}\n" \
        "Batch expiry: #{batch_expiry}"
    end

    def fhir_user_performer(reference_id:)
      FHIR::Immunization::Performer.new(
        actor: FHIR::Reference.new(reference: "##{reference_id}")
      )
    end

    private_class_method def self.user_performer_name_from_fhir(fhir_record)
      performer_references =
        fhir_record
          .performer
          .reject { it.actor&.type == "Organization" }
          .map { it.actor.reference&.sub("#", "") }
      user_actor =
        fhir_record.contained.find do |c|
          c.id.in?(performer_references) && c.resourceType == "Practitioner"
        end
      user_actor&.name&.find { it&.use == "official" } ||
        user_actor&.name&.first
    end

    def fhir_org_performer
      FHIR::Immunization::Performer.new(
        actor: Organisation.fhir_reference(ods_code: performed_ods_code)
      )
    end

    private_class_method def self.org_performer_ods_code_from_fhir(fhir_record)
      org_actor =
        fhir_record.performer.find { it.actor&.type == "Organization" }&.actor
      org_actor&.identifier&.value
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

    private_class_method def self.programme_from_fhir(fhir_record)
      target_diseases = fhir_record.protocolApplied.first.targetDisease
      target_diseases_codes =
        target_diseases.map do |disease|
          disease
            .coding
            .find { |coding| coding.system == "http://snomed.info/sct" }
            .code
        end
      # This may need to change when we start consuming programmes which have multiple target diseases, eg MMR
      target_disease_code = target_diseases_codes.first

      ::Programme.find_by(
        type: ::Programme::SNOMED_TARGET_DISEASE_CODES.key(target_disease_code)
      )
    end

    private_class_method def self.batch_from_fhir(fhir_record, vaccine:)
      ::Batch.create_with(archived_at: Time.current).find_or_create_by!(
        expiry: fhir_record.expirationDate&.to_date,
        name: fhir_record.lotNumber.to_s,
        vaccine:
      )
    end
  end
end
