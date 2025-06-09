# frozen_string_literal: true

# Normally we test this concern in isolation, but in this case it's bespoke to
# the PatientRecord and has a lot of dependencies on it, so not really worth it.
describe PatientFHIRConcern do
  include FHIRHelper

  let(:patient) { create(:patient, gender_code: :female) }

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

    describe "name" do
      subject { patient_record.name[0] }

      its(:family) { is_expected.to eq patient.family_name }
      its(:given) { is_expected.to eq [patient.given_name] }
    end

    describe "address" do
      subject { patient_record.address[0] }

      its(:postalCode) { is_expected.to eq patient.address_postcode }
    end

    describe "gender" do
      subject { patient_record.gender }

      it { should eq patient.gender_code }
    end
  end

  describe "#fhir_id" do
    it "returns the correct FHIR ID" do
      expect(patient.fhir_id).to eq "Patient/#{patient.id}"
    end
  end

  describe "#gender_fhir_value" do
    subject { patient.gender_fhir_value }

    context "is not_known" do
      let(:patient) { create(:patient, gender_code: :not_known) }
      it { should eq "unknown" }
    end

    context "is not_specified" do
      let(:patient) { create(:patient, gender_code: :not_specified) }
      it { should eq "other" }
    end

    context "is female" do
      let(:patient) { create(:patient, gender_code: :female) }
      it { should eq "female" }
    end

    context "is male" do
      let(:patient) { create(:patient, gender_code: :male) }
      it { should eq "male" }
    end
  end
end
