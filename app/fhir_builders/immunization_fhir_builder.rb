class ImmunizationFHIRBuilder
  attr_reader :patient_identifier, :lot_number

  def initialize(
    occurrence_date_time:,
    patient_identifier: "example",
    lot_number: "808"
  )
    @patient_identifier = patient_identifier
    @lot_number = lot_number
    @occurrence_date_time = occurrence_date_time
  end

  def ukcore_immunization_meta
    FHIR::Meta.new(
      profile: "https://fhir.hl7.org.uk/StructureDefinition/UKCore-Immunization"
    )
  end

  def app_identity
    Random.uuid
  end

  def identifier
    FHIR::Identifier.new(
      system: "https://supplierABC/identifiers/vacc",
      value: app_identity
    )
  end

  def patient
    # This appears to be the Right Way to encode a patient, however this doesn't
    # match the JSON taken from Graham's POC POC in our test. We'll build it
    # ourselves below for now.
    #
    # FHIR::Patient.new(
    #   identifier: FHIR::Identifier.new(
    #     system: "https://fhir.nhs.uk/Id/nhs-number",
    #     value: patient_identifier,
    #   ),
    # )

    {
      identifier:
        FHIR::Identifier.new(
          system: "https://fhir.nhs.uk/Id/nhs-number",
          value: patient_identifier
        ),
      reference:
        "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{patient_identifier}",
      type: "Patient"
    }
  end

  # This is how we might retrieve patient info using the provided identifier,
  # however we don't need this quite yet.
  #
  # def patient
  #   @patient ||= FHIR::Patient.read(@patient_identifier)
  # end

  def vaccine_procedure_extension
    @vaccine_procedure_extension ||=
      FHIR::Extension.new(
        url:
          "https://fhir.hl7.org.uk/StructureDefinition/Extension-UKCore-VaccinationProcedure",
        valueCodeableConcept:
          FHIR::CodeableConcept.new(
            coding:
              FHIR::Coding.new(
                system: "https://snomed.info/sct",
                code: "734152003",
                display:
                  "Administration of vaccine product containing only Human papillomavirus 6, 11, 16 and 18 antigens"
              )
          )
      )
  end

  def dose_quantity
    FHIR::Quantity.new(
      value: 0.5,
      unit: "Millilitre",
      system: "https://snomed.info/sct",
      code: "258773002"
    )
  end

  def reason_code
    FHIR::CodeableConcept.new(
      coding:
        FHIR::Coding.new(
          code: "443684005",
          display: "Disease outbreak",
          system: "https://snomed.info/sct"
        )
    )
  end

  def route
    FHIR::CodeableConcept.new(
      coding:
        FHIR::Coding.new(
          system: "https://snomed.info/sct",
          code: "78421000",
          display: "Intramuscular route (qualifier value)"
        )
    )
  end

  def site
    FHIR::CodeableConcept.new(
      coding:
        FHIR::Coding.new(
          system: "https://snomed.info/sct",
          code: "368209003",
          display: "Right upper arm structure (body structure)"
        )
    )
  end

  def vaccine_code
    FHIR::CodeableConcept.new(
      coding:
        FHIR::Coding.new(
          system: "https://snomed.info/sct",
          code: "10880211000001104",
          display:
            "Gardasil vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd)"
        )
    )
  end

  def immunization
    @immunization ||=
      FHIR::Immunization.new.tap do |imm|
        # TODO: Get these from the vaccination record
        imm.meta = ukcore_immunization_meta
        imm.extension << vaccine_procedure_extension
        imm.identifier << identifier
        imm.patient = patient
        imm.doseQuantity = dose_quantity
        imm.lotNumber = "808"
        imm.primarySource = true
        imm.reasonCode << reason_code
        imm.expirationDate = "2023-01-31"
        imm.occurrenceDateTime = @occurrence_date_time.rfc3339
        imm.recorded = "2023-01-25"
        imm.status = "completed"
        imm.route = route
        imm.site = site
        imm.vaccineCode = vaccine_code
      end
  end
end
