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
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_cohort_imports_on_organisation_id      (organisation_id)
#  index_cohort_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe CohortImport do
  subject(:cohort_import) { create(:cohort_import, csv:, organisation:) }

  let(:programme) { create(:programme) }
  let(:organisation) { create(:organisation, programmes: [programme]) }

  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/cohort_import/#{file}") }

  # Ensure location URN matches the URN in our fixture files
  let!(:location) { create(:school, urn: "123456", organisation:) }

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

        patient = cohort_import.rows.first.to_patient
        expect(patient).to have_attributes(
          given_name: "Jennifer",
          family_name: "Clarke",
          date_of_birth: Date.new(2010, 1, 1)
        )

        expect(
          cohort_import.rows.first.to_school_move(patient)
        ).to have_attributes(school: location)
      end
    end

    describe "with a valid file using ISO-8859-1 encoding" do
      let(:file) { "valid_iso_8859_1_encoding.csv" }

      let(:location) do
        Location.find_by(urn: "120026") || create(:school, urn: "120026")
      end

      it "is valid" do
        expect(cohort_import).to be_valid
        expect(cohort_import.rows.count).to eq(16)
      end

      it "detected the encoding" do
        expect(cohort_import.detect_encoding).to eq("ISO-8859-1")
      end
    end

    describe "with an invalid file using ISO-8859-1 encoding" do
      let(:file) { "invalid_iso_8859_1_encoding.csv" }

      it "is invalid" do
        expect(cohort_import).to be_invalid
      end

      it "detected the encoding" do
        expect(cohort_import.detect_encoding).to eq("ISO-8859-1")
      end
    end
  end

  describe "#process!" do
    subject(:process!) { cohort_import.process! }

    let(:file) { "valid.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { process! }
        .to change(cohort_import, :processed_at).from(nil)
        .and change(cohort_import.patients, :count).by(3)
        .and change(cohort_import.parents, :count).by(3)

      expect(Patient.first).to have_attributes(
        nhs_number: "1234567890",
        date_of_birth: Date.new(2010, 1, 1),
        given_name: "Jennifer",
        family_name: "Clarke",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.first.parents).to be_empty

      expect(Patient.second).to have_attributes(
        nhs_number: "1234567891",
        date_of_birth: Date.new(2010, 1, 2),
        given_name: "Jimmy",
        family_name: "Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.second.parents.count).to eq(1)

      expect(Patient.second.parents.first).to have_attributes(
        full_name: "John Smith",
        phone: "07412 345678",
        email: "john@example.com"
      )

      expect(Patient.second.parent_relationships.first).to be_father

      expect(Patient.third).to have_attributes(
        nhs_number: nil,
        date_of_birth: Date.new(2010, 1, 3),
        given_name: "Mark",
        family_name: "Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.third.parents.count).to eq(2)

      expect(Patient.third.parents.first).to have_attributes(
        full_name: "Jane Doe",
        phone: "07412 345679",
        email: "jane@example.com"
      )

      expect(Patient.third.parents.first).to have_attributes(
        full_name: "Jane Doe",
        phone: "07412 345679",
        email: "jane@example.com"
      )

      expect(Patient.third.parent_relationships.first).to be_mother
      expect(Patient.third.parent_relationships.second).to be_father

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
        .and change(cohort_import, :new_record_count).to(3)
        .and change(cohort_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      create(:cohort_import, csv:, organisation:).process!
      csv.rewind

      process!
      expect(cohort_import.exact_duplicate_record_count).to eq(3)
    end

    it "enqueues jobs to look up missing NHS numbers" do
      expect { process! }.to have_enqueued_job(
        PatientNHSNumberLookupJob
      ).once.on_queue(:imports)
    end

    it "enqueues jobs to update from PDS" do
      expect { process! }.to have_enqueued_job(
        PatientUpdateFromPDSJob
      ).twice.on_queue(:imports)
    end

    context "when same NHS number appears multiple times in the file" do
      let(:file) { "duplicate_nhs_numbers.csv" }

      it "has a validation error" do
        expect { process! }.not_to change(Patient, :count)
        expect(cohort_import.errors[:row_2]).to eq(
          [
            [
              "<code>CHILD_NHS_NUMBER</code>: The same NHS number appears multiple times in this file."
            ]
          ]
        )
        expect(cohort_import.errors[:row_3]).to eq(
          [
            [
              "<code>CHILD_NHS_NUMBER</code>: The same NHS number appears multiple times in this file."
            ]
          ]
        )
      end
    end

    context "with an existing patient matching the name" do
      before do
        create(
          :patient,
          given_name: "Jimmy",
          family_name: "Smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil,
          organisation:
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(2)
      end
    end

    context "with an existing patient matching the name but a different case" do
      before do
        create(
          :patient,
          given_name: "JIMMY",
          family_name: "smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil,
          organisation:
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(2)
      end
    end

    context "with an unscheduled session" do
      let(:session) do
        create(:session, :unscheduled, organisation:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { process! }.to change(session.patients, :count).from(0).to(3)
      end
    end

    context "with a scheduled session" do
      let(:session) do
        create(:session, :scheduled, organisation:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { process! }.to change(session.patients, :count).from(0).to(3)
      end
    end
  end
end
