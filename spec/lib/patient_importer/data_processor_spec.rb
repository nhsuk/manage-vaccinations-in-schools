# frozen_string_literal: true

describe PatientImporter::DataProcessor do
  subject(:processed_patient_data) { described_class.call(row_data) }

  let(:school) { build(:school) }
  let(:valid_row_data) do
    {
      date_of_birth: "2010-01-01".to_date,
      family_name: "Smith",
      given_name: "Jimmy",
      address_postcode: "SW1A 1AA",
      registration: "8AB",
      parent_1_email: "mary.smith@example.com",
      parent_1_phone: "07412345678"
    }
  end

  describe "#call" do
    let(:row_data) { valid_row_data }

    describe "patient result" do
      context "when patient doesn't exist" do
        it "creates a new patient with the correct attributes" do
          patient = processed_patient_data.patient

          expect(patient.date_of_birth.to_s).to eq("2010-01-01")
          expect(patient.family_name).to eq("Smith")
          expect(patient.gender_code).to eq("not_known")
          expect(patient.given_name).to eq("Jimmy")
          expect(patient.registration).to eq("8AB")
          expect(patient.home_educated).to be(false)
          expect(patient.attributes).not_to include("extra_field")
        end
      end

      context "with an existing patient without preferred names" do
        let(:row_data) do
          valid_row_data.merge(
            preferred_given_name: "Jenny",
            preferred_family_name: "Jones"
          )
        end

        let!(:existing_patient) do
          create(
            :patient,
            address_postcode: "SW1A 1AA",
            family_name: "Smith",
            given_name: "Jimmy",
            date_of_birth: Date.new(2010, 1, 1)
          )
        end

        it "returns the existing patient" do
          expect(processed_patient_data.patient).to eq(existing_patient)
        end

        it "assigns the incoming preferred names to the existing patient" do
          expect(processed_patient_data.patient).to have_attributes(
            preferred_family_name: "Jones",
            preferred_given_name: "Jenny"
          )
        end

        it "doesn't stage the preferred names differences" do
          expect(processed_patient_data.patient.pending_changes).to be_empty
        end
      end

      context "with an existing patient without address" do
        let(:result) { processed_patient_data.process }

        let(:row_data) do
          valid_row_data.merge(
            address_line_1: "10 Downing Street",
            address_line_2: "",
            address_postcode: "SW1A 1AA",
            address_town: "London"
          )
        end

        let!(:existing_patient) do
          create(
            :patient,
            family_name: "Smith",
            given_name: "Jimmy",
            gender_code: "male",
            nhs_number: "9990000018",
            birth_academic_year: 2009,
            date_of_birth: Date.new(2010, 1, 1),
            registration: "8AB",
            address_line_1: nil,
            address_line_2: nil,
            address_town: nil,
            address_postcode: "SW1A 1AA"
          )
        end

        it "returns the existing patient" do
          expect(processed_patient_data.patient).to eq(existing_patient)
        end

        it "assigns the incoming preferred names to the existing patient" do
          expect(processed_patient_data.patient).to have_attributes(
            address_line_1: "10 Downing Street",
            address_line_2: "",
            address_town: "London",
            address_postcode: "SW1A 1AA"
          )
        end

        it "doesn't stage the preferred names differences" do
          expect(processed_patient_data.patient.pending_changes).to be_empty
        end
      end

      context "with an existing patient without gender" do
        let(:result) { processed_patient_data.process }

        let(:row_data) { valid_row_data.merge(gender_code: "male") }

        let!(:existing_patient) do
          create(
            :patient,
            address_postcode: "SW1A 1AA",
            family_name: "Smith",
            gender_code: "not_known",
            given_name: "Jimmy",
            date_of_birth: Date.new(2010, 1, 1)
          )
        end

        it "returns the existing patient" do
          expect(processed_patient_data.patient).to eq(existing_patient)
        end

        it "assigns the incoming gender to the existing patient" do
          expect(processed_patient_data.patient).to have_attributes(
            gender_code: "male"
          )
        end

        it "doesn't stage the preferred names differences" do
          expect(processed_patient_data.patient.pending_changes).to be_empty
        end
      end

      context "with an existing patient already with an address (with a different postcode)" do
        let(:result) { processed_patient_data.process }

        let(:row_data) do
          valid_row_data.merge(
            address_line_1: "10 Downing Street",
            address_line_2: "",
            address_postcode: "SW1A 1AA",
            address_town: "London"
          )
        end

        let!(:existing_patient) do
          create(
            :patient,
            family_name: "Smith",
            gender_code: "male",
            given_name: "Jimmy",
            nhs_number: "9990000018",
            address_line_1: "20 Woodstock Road",
            address_line_2: "",
            address_town: "Oxford",
            address_postcode: "OX2 6HD",
            birth_academic_year: 2009,
            date_of_birth: Date.new(2010, 1, 1),
            registration: "8AB"
          )
        end

        it "returns the existing patient" do
          expect(processed_patient_data.patient).to eq(existing_patient)
        end

        it "does not save the incoming address" do
          expect(processed_patient_data.patient).to have_attributes(
            address_line_1: "20 Woodstock Road",
            address_line_2: "",
            address_town: "Oxford",
            address_postcode: "OX2 6HD"
          )
        end

        it "does stage the address differences" do
          expect(processed_patient_data.patient.pending_changes).to include(
            "address_line_1" => "10 Downing Street",
            "address_postcode" => "SW1A 1AA",
            "address_town" => "London"
          )
        end
      end

      context "with an existing patient already with an address (with the same postcode)" do
        let(:result) { processed_patient_data.process }

        let(:row_data) do
          valid_row_data.merge(
            address_line_1: "10 Downing Street",
            address_line_2: "",
            address_postcode: "SW1A 1AA",
            address_town: "London"
          )
        end

        let!(:existing_patient) do
          create(
            :patient,
            family_name: "Smith",
            gender_code: "male",
            given_name: "Jimmy",
            nhs_number: "9990000018",
            address_line_1: "20 Woodstock Road",
            address_line_2: "",
            address_town: "Oxford",
            address_postcode: "SW1A 1AA",
            birth_academic_year: 2009,
            date_of_birth: Date.new(2010, 1, 1),
            registration: "8AB"
          )
        end

        it "returns the existing patient" do
          expect(processed_patient_data.patient).to eq(existing_patient)
        end

        it "assigns the address attributes to the existing patient" do
          expect(processed_patient_data.patient).to have_attributes(
            address_line_1: "10 Downing Street",
            address_line_2: "",
            address_town: "London",
            address_postcode: "SW1A 1AA"
          )
        end

        it "doesn't stage the address differences" do
          expect(processed_patient_data.patient.pending_changes).to be_empty
        end
      end
    end
  end
end
