require "rails_helper"

RSpec.describe CohortList, type: :model do
  subject(:cohort_list) { described_class.new(csv:) }

  let(:csv) { fixture_file_upload("spec/fixtures/cohort_list/#{file}") }

  describe "with missing CSV" do
    let(:csv) { nil }

    it "is invalid" do
      expect(cohort_list).to be_invalid
      expect(cohort_list.errors[:csv]).to include(/Choose/)
    end
  end

  describe "with malformed CSV" do
    let(:file) { "malformed.csv" }

    it "is invalid" do
      expect(cohort_list).to be_invalid
      expect(cohort_list.errors[:csv]).to include(/correct format/)
    end
  end

  describe "#generate_cohort!" do
    describe "with invalid headers" do
      let(:file) { "invalid_headers.csv" }

      it "populates errors" do
        cohort_list.valid?
        cohort_list.generate_cohort!

        expect(cohort_list.errors[:csv]).to include(/missing.*headers/)
      end
    end

    describe "with invalid fields" do
      let(:file) { "invalid_fields.csv" }

      it "populates errors" do
        cohort_list.valid?
        cohort_list.generate_cohort!

        expect(cohort_list.errors[:row_0]).not_to be_empty
      end
    end

    describe "with valid fields" do
      let(:file) { "valid_cohort.csv" }

      it "is valid" do
        cohort_list.valid?
        cohort_list.generate_cohort!

        expect(cohort_list).to be_valid
      end
    end
  end
end
