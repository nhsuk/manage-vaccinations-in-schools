# frozen_string_literal: true

require "csv"

describe DPSExportRow do
  subject(:row) { described_class.new(vaccination_record) }

  let(:team) { create(:team) }
  let(:vaccine) { create(:vaccine, :gardasil_9, dose: 0.5) }
  let(:programme) do
    create(:programme, type: vaccine.type, team:, vaccines: [vaccine])
  end
  let(:location) { create(:location, :school) }
  let(:school) { create(:location, :school) }
  let(:patient) do
    create(:patient, date_of_birth: Date.new(2012, 12, 29), school:)
  end
  let(:session) { create(:session, programme:, location:) }
  let(:patient_session) { create(:patient_session, patient:, session:) }
  let(:performed_by) { create(:user, family_name: "Doe", given_name: "Jane") }
  let(:performed_by_given_name) { nil }
  let(:performed_by_family_name) { nil }
  let(:vaccination_record) do
    create(
      :vaccination_record,
      batch: create(:batch, vaccine:, name: "AB1234", expiry: "2025-07-01"),
      created_at: Time.zone.local(2024, 6, 12, 11, 28, 31),
      delivery_method: :intramuscular,
      delivery_site: :left_arm_upper_position,
      dose_sequence: 1,
      patient_session:,
      performed_by:,
      performed_by_given_name:,
      performed_by_family_name:,
      recorded_at: Time.zone.local(2024, 7, 23, 19, 31, 47),
      uuid: "ea4860a5-6d97-4f31-b640-f5c50f43bfd2",
      vaccine:
    )
  end

  describe "to_a" do
    subject(:array) { row.to_a }

    it "has the nhs_number" do
      expect(array[0]).to eq vaccination_record.patient.nhs_number
    end

    it "has person_firstname" do
      expect(array[1]).to eq vaccination_record.patient.first_name
    end

    it "has person_surname" do
      expect(array[2]).to eq vaccination_record.patient.last_name
    end

    it "has person_dob" do
      expect(array[3]).to eq "20121229"
    end

    it "has person_gender_code" do
      expect(
        array[4]
      ).to eq vaccination_record.patient.gender_code_before_type_cast
    end

    it "has person_postcode" do
      expect(array[5]).to eq vaccination_record.patient.address_postcode
    end

    it "has date_and_time" do
      expect(array[6]).to eq "20240723T19314700"
    end

    it "has site_code" do
      expect(array[7]).to eq vaccination_record.programme.team.ods_code
    end

    it "has site_code_type_uri" do
      expect(array[8]).to eq "https://fhir.nhs.uk/Id/ods-organization-code"
    end

    describe "unique_id" do
      subject(:unique_id) { array[9] }

      it { should eq("ea4860a5-6d97-4f31-b640-f5c50f43bfd2") }
    end

    describe "unique_id_uri" do
      it "is expected to be valid" do
        expect(array[10]).to eq(
          "https://manage-vaccinations-in-schools.nhs.uk/vaccination-records"
        )
      end
    end

    it "has action_flag" do
      expect(array[11]).to eq "new"
    end

    describe "performing_professional_forename" do
      subject(:performing_professional_forename) { array[12] }

      it { should eq("Jane") }

      context "without a user" do
        let(:performed_by) { nil }

        it { should be_nil }

        context "with a name" do
          let(:performed_by_given_name) { "Jane" }

          it { should eq("Jane") }
        end
      end
    end

    describe "performing_professional_surname" do
      subject(:performing_professional_surname) { array[13] }

      it { should eq("Doe") }

      context "without a user" do
        let(:performed_by) { nil }

        it { should be_nil }

        context "with a name" do
          let(:performed_by_family_name) { "Doe" }

          it { should eq("Doe") }
        end
      end
    end

    it "has recorded_date" do
      expect(array[14]).to eq "20240612"
    end

    it "has primary_source" do
      expect(array[15]).to eq "TRUE"
    end

    it "has vaccination_procedure_code" do
      expect(array[16]).to eq "761841000"
    end

    it "has vaccination_procedure_term" do
      expect(
        array[17]
      ).to eq "Administration of vaccine product containing only Human papillomavirus antigen (procedure)"
    end

    describe "dose_sequence" do
      subject(:dose_sequence) { array[18] }

      it { should eq("1") }
    end

    it "has vaccine_product_code" do
      expect(array[19]).to eq "33493111000001108"
    end

    it "has vaccine_product_term" do
      expect(
        array[20]
      ).to eq "Gardasil 9 vaccine suspension for injection 0.5ml pre-filled syringes" \
           " (Merck Sharp & Dohme (UK) Ltd) (product)"
    end

    it "has vaccine_manufacturer" do
      expect(array[21]).to eq "Merck Sharp & Dohme"
    end

    it "has batch_number" do
      expect(array[22]).to eq "AB1234"
    end

    it "has expiry_date" do
      expect(array[23]).to eq "20250701"
    end

    it "has site_of_vaccination_code" do
      expect(array[24]).to eq "368208006"
    end

    it "has site_of_vaccination_term" do
      expect(array[25]).to eq "Structure of left upper arm (body structure)"
    end

    context "when the vaccine is a nasal spray" do
      let(:vaccine) { create :vaccine, :fluenz_tetra }

      let(:vaccination_record) do
        create(
          :vaccination_record,
          vaccine:,
          batch: create(:batch, vaccine:),
          delivery_site: :nose,
          delivery_method: :nasal_spray
        )
      end

      it "has route_of_vaccination_code" do
        expect(array[26]).to eq "46713006"
      end

      it "has route_of_vaccination_term" do
        expect(array[27]).to eq "Nasal route (qualifier value)"
      end
    end

    context "when the vaccine is an intramuscular injection" do
      let(:vaccine) { create :vaccine, :quadrivalent_influenza }

      it "has route_of_vaccination_code" do
        expect(array[26]).to eq "78421000"
      end

      it "has route_of_vaccination_term" do
        expect(array[27]).to eq "Intramuscular route (qualifier value)"
      end
    end

    it "has dose_amount" do
      expect(array[28]).to eq 0.5
    end

    it "has dose_unit_code" do
      expect(array[29]).to eq "258773002"
    end

    it "has dose_unit_term" do
      expect(array[30]).to eq "Milliliter (qualifier value)"
    end

    it "has indication_code" do
      expect(array[31]).to be_nil
    end

    describe "location_code" do
      subject(:location_code) { array[32] }

      it { should_not be_nil }

      context "when the session has a location with a URN" do
        let(:location) { create(:location, :school, urn: "12345") }

        it { should eq("12345") }
      end

      context "when the session has a location with an ODS code" do
        let(:location) { create(:location, :generic_clinic, ods_code: "12345") }

        it { should eq("12345") }
      end

      context "when the session doesn't have a location" do
        let(:location) { nil }
        let(:team) { create(:team, ods_code: "ABC") }

        it { should eq("ABC") }
      end
    end

    describe "location_code_type_uri" do
      subject(:location_code_type_uri) { array[33] }

      it { should_not be_nil }

      context "when the session has a location with a URN" do
        let(:location) { create(:location, :school) }

        it { should eq("https://fhir.hl7.org.uk/Id/urn-school-number") }
      end

      context "when the session has a location without a URN" do
        let(:location) { create(:location, :generic_clinic) }

        it { should eq("https://fhir.nhs.uk/Id/ods-organization-code") }
      end

      context "when the session doesn't have a location" do
        let(:location) { nil }

        it { should eq("https://fhir.nhs.uk/Id/ods-organization-code") }
      end
    end
  end
end
