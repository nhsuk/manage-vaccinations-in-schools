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
#  recorded_at                  :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  programme_id                 :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_organisation_id      (organisation_id)
#  index_cohort_imports_on_programme_id         (programme_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe CohortImport do
  subject(:cohort_import) do
    create(:cohort_import, csv:, programme:, organisation:)
  end

  let(:programme) { create(:programme) }
  let(:organisation) { create(:organisation, programmes: [programme]) }

  let(:file) { "valid.csv" }
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
      let(:file) { "valid_extra_fields.csv" }

      it "populates rows" do
        expect(cohort_import).to be_valid
      end
    end

    describe "with valid fields" do
      let(:file) { "valid.csv" }

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

    describe "with minimal fields" do
      let(:file) { "valid_minimal.csv" }

      it "is valid" do
        expect(cohort_import).to be_valid
        expect(cohort_import.rows.count).to eq(1)
        expect(cohort_import.rows.first.to_patient).to have_attributes(
          given_name: "Jennifer",
          family_name: "Clarke",
          date_of_birth: Date.new(2010, 1, 1),
          school: location
        )
      end
    end
  end

  describe "#record!" do
    subject(:record!) { cohort_import.record! }

    let(:file) { "valid.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { record! }
        .to change(cohort_import, :recorded_at).from(nil)
        .and change(cohort_import.patients, :count).by(3)
        .and change(cohort_import.parents, :count).by(3)
        .and change(organisation.cohorts, :count).by(1)

      cohort = Cohort.first
      expect(cohort.birth_academic_year).to eq(2009)
      expect(cohort.patients.pluck(:id)).to match_array(Patient.pluck(:id))

      expect(Patient.first).to have_attributes(
        nhs_number: "1234567890",
        date_of_birth: Date.new(2010, 1, 1),
        full_name: "Jennifer Clarke",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.first.parents).to be_empty

      expect(Patient.second).to have_attributes(
        nhs_number: "1234567891",
        date_of_birth: Date.new(2010, 1, 2),
        full_name: "Jimmy Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.second.parents.count).to eq(1)

      expect(Patient.second.parents.first).to have_attributes(
        full_name: "John Smith",
        phone: "07412345678",
        email: "john@example.com"
      )

      expect(Patient.second.parent_relationships.first).to be_father

      expect(Patient.third).to have_attributes(
        nhs_number: nil,
        date_of_birth: Date.new(2010, 1, 3),
        full_name: "Mark Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.third.parents.count).to eq(2)

      expect(Patient.third.parents.first).to have_attributes(
        full_name: "Jane Doe",
        phone: "07412345679",
        email: "jane@example.com"
      )

      expect(Patient.third.parents.first).to have_attributes(
        full_name: "Jane Doe",
        phone: "07412345679",
        email: "jane@example.com"
      )

      expect(Patient.third.parent_relationships.first).to be_mother
      expect(Patient.third.parent_relationships.second).to be_father

      # Second import should not duplicate the patients if they're identical.

      # stree-ignore
      expect { cohort_import.record! }
        .to not_change(cohort_import, :recorded_at)
        .and not_change(Patient, :count)
        .and not_change(Parent, :count)
        .and not_change(Cohort, :count)
    end

    it "stores statistics on the import" do
      # stree-ignore
      expect { record! }
        .to change(cohort_import, :exact_duplicate_record_count).to(0)
        .and change(cohort_import, :new_record_count).to(3)
        .and change(cohort_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      create(:cohort_import, csv:, organisation:, programme:).record!
      csv.rewind

      record!
      expect(cohort_import.exact_duplicate_record_count).to eq(3)
    end

    it "enqueues jobs to look up missing NHS numbers" do
      expect { record! }.to have_enqueued_job(
        PatientNHSNumberLookupJob
      ).once.on_queue(:imports)
    end

    it "enqueues jobs to update from PDS" do
      expect { record! }.to have_enqueued_job(
        PatientUpdateFromPDSJob
      ).twice.on_queue(:imports)
    end

    context "with an existing patient matching the name" do
      before do
        create(
          :patient,
          given_name: "Jimmy",
          family_name: "Smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { record! }.to change(Patient, :count).by(2)
      end
    end

    context "with an existing patient matching the name but a different case" do
      before do
        create(
          :patient,
          given_name: "JIMMY",
          family_name: "smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { record! }.to change(Patient, :count).by(2)
      end
    end

    it "records the parents" do
      expect { record! }.to change(Parent.recorded, :count).from(0).to(3)
    end

    context "with an unscheduled session" do
      let(:session) do
        create(:session, :unscheduled, organisation:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { record! }.to change(session.patients, :count).from(0).to(3)
      end
    end

    context "with a scheduled session" do
      let(:session) do
        create(:session, :scheduled, organisation:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { record! }.to change(session.patients, :count).from(0).to(3)
      end
    end

    context "with a closed session" do
      before { create(:session, :closed, organisation:, programme:, location:) }

      it "doesn't add the patients to the session" do
        expect { record! }.not_to change(PatientSession, :count)
      end
    end
  end
end
