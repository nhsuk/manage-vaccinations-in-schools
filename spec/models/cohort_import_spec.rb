# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_team_id              (team_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe CohortImport do
  subject(:cohort_import) { create(:cohort_import, csv:, team:) }

  let(:team) { create(:team) }
  let(:file) { "valid_cohort.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/cohort_import/#{file}") }
  # Ensure location URN matches the URN in our fixture files
  let!(:location) do
    Location.find_by(urn: "123456") || create(:location, :school, urn: "123456")
  end

  it_behaves_like "a CSVImportable model"

  describe "#load_data!" do
    subject(:load_data!) { cohort_import.load_data! }

    before { load_data! }

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(cohort_import).to be_invalid
        expect(cohort_import.errors[:csv]).to include(/correct format/)
      end
    end
  end

  describe "#parse_rows!" do
    subject(:parse_rows!) { cohort_import.parse_rows! }

    before { parse_rows! }

    describe "with invalid headers" do
      let(:file) { "invalid_headers.csv" }

      it "populates header errors" do
        expect(cohort_import).to be_invalid
        expect(cohort_import.errors[:csv]).to include(/missing.*headers/)
      end
    end

    describe "with invalid fields" do
      let(:file) { "invalid_fields.csv" }

      it "populates rows" do
        expect(cohort_import).to be_invalid
        expect(cohort_import.rows).not_to be_empty
      end
    end

    describe "with unrecognised fields" do
      let(:file) { "valid_cohort_extra_fields.csv" }

      it "populates rows" do
        expect(cohort_import).to be_valid
      end
    end

    describe "with valid fields" do
      let(:file) { "valid_cohort.csv" }

      it "is valid" do
        expect(cohort_import).to be_valid
      end

      it "accepts NHS numbers with spaces, removes spaces" do
        expect(cohort_import).to be_valid
        expect(cohort_import.rows.second.to_patient[:nhs_number]).to eq(
          "1234567891"
        )
      end

      it "parses dates in the ISO8601 format" do
        expect(cohort_import).to be_valid
        expect(cohort_import.rows.first.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 1)
        )
      end

      it "parses dates in the DD/MM/YYYY format" do
        expect(cohort_import).to be_valid
        expect(cohort_import.rows.second.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 2)
        )
      end
    end
  end

  describe "#process!" do
    subject(:process!) { cohort_import.process! }

    let(:file) { "valid_cohort.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { process! }
        .to change(cohort_import, :processed_at).from(nil)
        .and change(cohort_import.patients, :count).by(2)
        .and change(cohort_import.parents, :count).by(2)
        .and change(team.cohorts, :count).by(1)

      expect(Cohort.first).to have_attributes(
        patients: Patient.all,
        reception_starting_year: 2014
      )

      expect(Patient.first).to have_attributes(
        nhs_number: "1234567890",
        date_of_birth: Date.new(2010, 1, 1),
        full_name: "Jimmy Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.first.parents.first).to have_attributes(
        name: "John Smith",
        phone: "07412345678",
        email: "john@example.com"
      )

      expect(Patient.first.parent_relationships.first).to be_father

      expect(Patient.first.parents.first).not_to be_recorded

      expect(Patient.second).to have_attributes(
        nhs_number: "1234567891",
        date_of_birth: Date.new(2010, 1, 2),
        full_name: "Mark Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.second.parents.first).not_to be_recorded

      expect(Patient.second.parents.first).to have_attributes(
        name: "Jane Doe",
        phone: "07412345679",
        email: "jane@example.com"
      )

      expect(Patient.second.parent_relationships.first).to be_mother

      # Second import should not duplicate the patients if they're identical.

      # stree-ignore
      expect { cohort_import.process! }
        .to not_change(cohort_import, :processed_at)
        .and not_change(Patient, :count)
        .and not_change(Parent, :count)
        .and not_change(Cohort, :count)
    end

    it "stores statistics on the import" do
      # stree-ignore
      expect { process! }
        .to change(cohort_import, :exact_duplicate_record_count).to(0)
        .and change(cohort_import, :new_record_count).to(2)
        .and change(cohort_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      build(:cohort_import, csv:).record!
      csv.rewind

      process!
      expect(cohort_import.exact_duplicate_record_count).to eq(2)
    end

    context "with an existing patient matching the name" do
      before do
        create(
          :patient,
          first_name: "Jimmy",
          last_name: "Smith",
          date_of_birth: Date.new(2010, 1, 1),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(1)
      end
    end
  end

  describe "#record!" do
    subject(:record!) { cohort_import.record! }

    let(:file) { "valid_cohort.csv" }

    it "records the parents" do
      expect { record! }.to change(Parent.recorded, :count).from(0).to(2)
    end
  end
end
