# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id         :bigint           not null, primary key
#  csv        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

describe ImmunisationImport do
  subject(:immunisation_import) { described_class.create!(csv:, user:) }

  let(:file) { "nivs.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:team) { create(:team, ods_code: "R1L") }
  let(:user) { create(:user, teams: [team]) }

  it { should validate_presence_of(:csv) }

  describe "#load_data!" do
    before { immunisation_import.load_data! }

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/correct format/)
      end
    end

    describe "with empty CSV" do
      let(:file) { "empty.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/one record/)
      end
    end

    describe "with missing headers" do
      let(:file) { "missing_headers.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/missing/)
      end
    end
  end

  describe "#parse_rows!" do
    before { immunisation_import.parse_rows! }

    it "populates the rows" do
      expect(immunisation_import).to be_valid
      expect(immunisation_import.rows).not_to be_empty
    end

    describe "with invalid rows" do
      let(:file) { "invalid_rows.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors).to include(:row_2)
      end
    end
  end

  describe "#process!" do
    it "creates locations and vaccination records" do
      # TEMPORARY: Pass in a dummy patient session. We will iterate this out.
      patient_session = create(:patient_session, user:)
      expect { immunisation_import.process!(patient_session:) }.to change(
        immunisation_import.vaccination_records,
        :count
      ).by(11).and change(Location, :count).by(4)
    end
  end
end
