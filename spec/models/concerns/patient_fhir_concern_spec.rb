# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the PatientRecord and has a lot of dependencies on it, so not really worth it.
describe PatientFHIRConcern do
  include FHIRHelper

  let(:patient) { create(:patient) }

  describe "#to_fhir" do
    subject(:patient_record) { patient.to_fhir }

    it "adds the NHS number" do
      expect(
        patient_record.identifier[0].system
      ).to eq "https://fhir.nhs.uk/Id/nhs-number"
      expect(patient_record.identifier[0].value).to eq patient.nhs_number
    end

    it "sets the fhir_id" do
      expect(patient_record.id).to eq "Patient/#{patient.id}"
    end
  end

  describe "#fhir_id" do
    it "returns the correct FHIR ID" do
      expect(patient.fhir_id).to eq "Patient/#{patient.id}"
    end
  end
end
