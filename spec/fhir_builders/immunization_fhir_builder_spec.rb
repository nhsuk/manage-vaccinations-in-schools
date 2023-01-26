require "rails_helper"

RSpec.describe ImmunizationFHIRBuilder do
  describe "JSON produced" do
    let(:target_json) { <<~EOJSON.freeze }
        {
          "resourceType": "Immunization",
          "meta": {
            "profile": [
              "https://fhir.hl7.org.uk/StructureDefinition/UKCore-Immunization"
            ]
          },
          "extension": [
            {
              "url": "https://fhir.hl7.org.uk/StructureDefinition/Extension-UKCore-VaccinationProcedure",
              "valueCodeableConcept": {
                "coding": [
                  {
                    "system": "http://snomed.info/sct",
                    "code": "734152003",
                    "display": "Administration of vaccine product containing only Human papillomavirus 6, 11, 16 and 18 antigens"
                  }
                ]
              }
            }
          ],
          "identifier": [
            {
              "system": "https://supplierABC/identifiers/vacc",
              "value": "5c1c14a6-37c2-45d3-9e0c-bffea36e13c7"
            }
          ],
          "status": "completed",
          "vaccineCode": {
            "coding": [
              {
                "system": "http://snomed.info/sct",
                "code": "10880211000001104",
                "display": "Gardasil vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd)"
              }
            ]
          },
          "patient": {
            "reference": "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{nhs_number}",
            "type": "Patient",
            "identifier": {
              "system": "https://fhir.nhs.uk/Id/nhs-number",
              "value": "#{nhs_number}"
            }
          },
          "occurrenceDateTime": "#{occurrence_date_time.rfc3339}",
          "recorded": "2023-01-25",
          "primarySource": true,
          "lotNumber": "808",
          "expirationDate": "2023-01-31",
          "site": {
            "coding": [
              {
                "system": "http://snomed.info/sct",
                "code": "368209003",
                "display": "Right upper arm structure (body structure)"
              }
            ]
          },
          "route": {
            "coding": [
              {
                "system": "http://snomed.info/sct",
                "code": "78421000",
                "display": "Intramuscular route (qualifier value)"
              }
            ]
          },
          "doseQuantity": {
            "value": 0.5,
            "unit": "Millilitre",
            "system": "http://snomed.info/sct",
            "code": "258773002"
          },
          "reasonCode": [
            {
              "coding": [
                {
                  "system": "http://snomed.info/sct",
                  "code": "443684005",
                  "display": "Disease outbreak"
                }
              ]
            }
          ]
        }
      EOJSON
    let(:app_identity) { "5c1c14a6-37c2-45d3-9e0c-bffea36e13c7" }
    let(:occurrence_date_time) { Time.zone.now }
    let(:nhs_number) { "9990000018" }

    before { allow(Random).to receive(:uuid).and_return(app_identity) }

    it "should match the JSON produced from the POC POC" do
      imm =
        described_class.new(
          patient_identifier: nhs_number,
          occurrence_date_time:
        )

      expect(JSON.parse(imm.immunization.to_json)).to eq(
        JSON.parse(target_json)
      )
    end

    it "allows setting of occurranceDateTime" do
      imm =
        described_class.new(
          patient_identifier: nhs_number,
          occurrence_date_time:
        )

      expect(JSON.parse(imm.immunization.to_json)).to eq(
        JSON.parse(target_json)
      )
    end
  end
end
