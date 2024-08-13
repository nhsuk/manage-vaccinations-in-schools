# frozen_string_literal: true

require "rails_helper"

describe CohortList, type: :model do
  subject(:cohort_list) { described_class.new(csv:, team:) }

  let(:team) { create(:team) }
  # Ensure location URN matches the URN in our fixture files
  let!(:location) do
    Location.find_by(urn: "123456") || create(:location, urn: "123456")
  end
  let(:csv) { fixture_file_upload("spec/fixtures/cohort_list/#{file}") }

  describe "#load_data!" do
    describe "with missing CSV" do
      let(:csv) { nil }

      it "is invalid" do
        cohort_list.load_data!

        expect(cohort_list).to be_invalid
        expect(cohort_list.errors[:csv]).to include(/Choose/)
      end
    end

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        cohort_list.load_data!

        expect(cohort_list).to be_invalid
        expect(cohort_list.errors[:csv]).to include(/correct format/)
      end
    end
  end

  describe "#parse_rows!" do
    describe "with invalid headers" do
      let(:file) { "invalid_headers.csv" }

      it "populates header errors" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_invalid
        expect(cohort_list.errors[:csv]).to include(/missing.*headers/)
      end
    end

    describe "with invalid fields" do
      let(:file) { "invalid_fields.csv" }

      it "populates rows" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_invalid
        expect(cohort_list.rows).not_to be_empty
      end
    end

    describe "with unrecognised fields" do
      let(:file) { "valid_cohort_extra_fields.csv" }

      it "populates rows" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
      end
    end

    describe "with valid fields" do
      let(:file) { "valid_cohort.csv" }

      it "is valid" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
      end

      it "accepts NHS numbers with spaces, removes spaces" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
        expect(cohort_list.rows.second.to_patient[:nhs_number]).to eq(
          "1234567891"
        )
      end

      it "parses dates in the ISO8601 format" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
        expect(cohort_list.rows.first.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 1)
        )
      end

      it "parses dates in the DD/MM/YYYY format" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
        expect(cohort_list.rows.second.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 2)
        )
      end
    end
  end

  describe "#generate_patients!" do
    let(:file) { "valid_cohort.csv" }

    it "creates patients" do
      cohort_list.load_data!
      cohort_list.parse_rows!

      expect { cohort_list.generate_patients! }.to change(Patient, :count).by(2)

      expect(Patient.first).to have_attributes(
        nhs_number: "1234567890",
        date_of_birth: Date.new(2010, 1, 1),
        full_name: "Jimmy Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.first.parent).to have_attributes(
        name: "John Smith",
        relationship: "father",
        phone: "07412345678",
        email: "john@example.com"
      )
      expect(Patient.first.parent.recorded_at).to be_present

      expect(Patient.second).to have_attributes(
        nhs_number: "1234567891",
        date_of_birth: Date.new(2010, 1, 2),
        full_name: "Mark Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )
      expect(Patient.second.parent.recorded_at).to be_present

      expect(Patient.second.parent).to have_attributes(
        name: "Jane Doe",
        relationship: "mother",
        phone: "07412345679",
        email: "jane@example.com"
      )
    end
  end
end
