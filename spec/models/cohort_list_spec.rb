require "rails_helper"

RSpec.describe CohortList, type: :model do
  subject(:cohort_list) { described_class.new(csv:) }

  let(:csv) { fixture_file_upload("spec/fixtures/cohort_list/#{file}") }

  before { create(:location, id: 1) if Location.count.zero? }

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

    describe "with valid fields" do
      let(:file) { "valid_cohort.csv" }

      it "is valid" do
        cohort_list.load_data!
        cohort_list.parse_rows!

        expect(cohort_list).to be_valid
      end
    end
  end

  describe "#generate_patients!" do
    let(:file) { "valid_cohort.csv" }

    it "creates patients" do
      cohort_list.load_data!
      cohort_list.parse_rows!

      expect { cohort_list.generate_patients! }.to change { Patient.count }.by(
        1
      )
    end
  end
end
