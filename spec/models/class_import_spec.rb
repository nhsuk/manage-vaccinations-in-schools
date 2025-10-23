# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
#
#  id                           :bigint           not null, primary key
#  academic_year                :integer          not null
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  year_groups                  :integer          default([]), not null, is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  location_id                  :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_location_id          (location_id)
#  index_class_imports_on_team_id              (team_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe ClassImport do
  subject(:class_import) { create(:class_import, csv:, session:, team:) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:team) { create(:team, :with_generic_clinic, programmes:) }
  let(:location) { create(:school, team:) }
  let(:session) { create(:session, location:, programmes:, team:) }

  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/class_import/#{file}") }

  it_behaves_like "a CSVImportable model"

  describe "#load_data!" do
    subject(:load_data!) { class_import.load_data! }

    before { load_data! }

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(class_import).to be_invalid
        expect(class_import.errors[:csv]).to include(/correct format/)
      end
    end
  end

  describe "#parse_rows!" do
    subject(:parse_rows!) { class_import.parse_rows! }

    before { parse_rows! }

    describe "with a BOM" do
      let(:file) { "valid_with_bom.csv" }

      it "removes the BOM" do
        expect(class_import).to be_valid
        expect(class_import.rows.first.to_patient[:given_name]).to eq("Lena")
      end
    end

    describe "with invalid fields" do
      let(:file) { "invalid_fields.csv" }

      it "populates rows" do
        expect(class_import).to be_invalid
        expect(class_import.rows).not_to be_empty
      end
    end

    describe "with unrecognised fields" do
      let(:file) { "valid_extra_fields.csv" }

      it "populates rows" do
        expect(class_import).to be_valid
      end
    end

    describe "with valid fields" do
      let(:file) { "valid.csv" }

      it "is valid" do
        expect(class_import).to be_valid
      end

      it "accepts NHS numbers with spaces, removes spaces" do
        expect(class_import).to be_valid
        expect(class_import.rows.second.to_patient[:nhs_number]).to eq(
          "9990000026"
        )
      end

      it "parses dates in the ISO8601 format" do
        expect(class_import).to be_valid
        expect(class_import.rows.first.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 1)
        )
      end

      it "parses dates in the DD/MM/YYYY format" do
        expect(class_import).to be_valid
        expect(class_import.rows.second.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 2)
        )
      end
    end

    describe "with minimal fields" do
      let(:file) { "valid_minimal.csv" }

      it "is valid" do
        expect(class_import).to be_valid
        expect(class_import.rows.count).to eq(1)

        patient = class_import.rows.first.to_patient
        expect(patient).to have_attributes(
          given_name: "Jennifer",
          family_name: "Clarke",
          date_of_birth: Date.new(2010, 1, 1)
        )

        expect(
          class_import.rows.first.to_school_move(patient)
        ).to have_attributes(school: location)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { class_import.process! }

    let(:file) { "valid.csv" }
    let(:configured_job) { instance_double(ActiveJob::ConfiguredJob) }

    before do
      allow(PDSCascadingSearchJob).to receive(:set).with(
        queue: :imports
      ).and_return(configured_job)
      allow(configured_job).to receive(:perform_later)
      allow(CommitPatientChangesetsJob).to receive(:perform_later)
    end

    context "when import_search_pds flag is enabled" do
      before { Flipper.enable(:import_search_pds) }
      after { Flipper.disable(:import_search_pds) }

      it "enqueues PDSCascadingSearchJob for each changeset" do
        process!

        expect(configured_job).to have_received(:perform_later).exactly(4).times

        expect(CommitPatientChangesetsJob).not_to have_received(:perform_later)
      end
    end

    context "when import_search_pds flag is disabled" do
      before { Flipper.disable(:import_search_pds) }

      it "marks all changesets as processed and enqueues CommitPatientChangesetsJob" do
        process!

        expect(CommitPatientChangesetsJob).to have_received(
          :perform_later
        ).with(class_import)

        expect(configured_job).not_to have_received(:perform_later)
      end
    end
  end

  describe "#pds_match_rate" do
    subject(:pds_match_rate) { class_import.pds_match_rate }

    context "when there are no changesets" do
      it { should eq(0) }
    end

    context "with some changesets" do
      before do
        create_list(
          :patient_changeset,
          4,
          :with_pds_match,
          import: class_import
        )
        create_list(:patient_changeset, 6, import: class_import)
      end

      it "returns percentage" do
        expect(pds_match_rate).to eq(40.0)
      end
    end

    context "with only some attempted searches" do
      before do
        create_list(
          :patient_changeset,
          4,
          :with_pds_match,
          import: class_import
        )
        create_list(
          :patient_changeset,
          6,
          :without_pds_search_attempted,
          import: class_import
        )
      end

      it "returns 100" do
        expect(pds_match_rate).to eq(100)
      end
    end
  end

  describe "#validate_pds_match_rate!" do
    subject(:validate_pds_match_rate!) { class_import.validate_pds_match_rate! }

    context "when match rate is equal to threshold" do
      before do
        create_list(
          :patient_changeset,
          7,
          :with_pds_match,
          import: class_import
        )
        create_list(:patient_changeset, 3, import: class_import)
      end

      it "does not mark as low_pds_match_rate" do
        validate_pds_match_rate!
        expect(class_import.reload.status).not_to eq("low_pds_match_rate")
      end
    end

    context "when match rate is below threshold and enough changesets" do
      before do
        create_list(
          :patient_changeset,
          6,
          :with_pds_match,
          import: class_import
        )
        create_list(:patient_changeset, 4, import: class_import)
      end

      it "marks the import as low_pds_match_rate" do
        validate_pds_match_rate!
        expect(class_import.reload.status).to eq("low_pds_match_rate")
      end
    end

    context "when there are fewer than 10 changesets" do
      before { create_list(:patient_changeset, 5, import: class_import) }

      it "skips validation" do
        validate_pds_match_rate!
        expect(class_import.reload.status).not_to eq("low_pds_match_rate")
      end
    end
  end
end
