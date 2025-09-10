# frozen_string_literal: true

describe FHIRMapper::Patient do
  let(:patient) { create(:patient, gender_code: :female) }

  describe "#fhir_record" do
    subject(:patient_fhir) do
      described_class.new(patient).fhir_record(reference_id: "Patient42")
    end

    it "adds the NHS number" do
      expect(
        patient_fhir.identifier[0].system
      ).to eq "https://fhir.nhs.uk/Id/nhs-number"

      expect(patient_fhir.identifier[0].value).to eq patient.nhs_number
    end

    it "sets the reference id" do
      expect(patient_fhir.id).to eq "Patient42"
    end

    describe "name" do
      subject { patient_fhir.name[0] }

      its(:family) { should eq patient.family_name }
      its(:given) { should eq [patient.given_name] }
    end

    describe "address" do
      subject { patient_fhir.address[0] }

      its(:postalCode) { should eq patient.address_postcode }

      context "when the address postcode is not set" do
        let(:patient) { create(:patient, address_postcode: nil) }

        its(:postalCode) { should eq "ZZ99 3WZ" }
      end
    end

    describe "gender" do
      subject { patient_fhir.gender }

      it { should eq patient.gender_code }
    end

    describe "gender fhir value" do
      subject { patient_fhir.gender }

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
end
