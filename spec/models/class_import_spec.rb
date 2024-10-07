# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
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
#  rows_count                   :integer
#  serialized_errors            :json
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  session_id                   :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_team_id              (team_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe ClassImport do
  subject(:class_import) { create(:class_import, csv:, session:, team:) }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:location) { create(:location, :school, team:) }
  let(:session) { create(:session, location:, programme:, team:) }

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

    describe "with invalid headers" do
      let(:file) { "invalid_headers.csv" }

      it "populates header errors" do
        expect(class_import).to be_invalid
        expect(class_import.errors[:csv]).to include(/missing.*headers/)
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
          "1234567891"
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
  end

  describe "#process!" do
    subject(:process!) { class_import.process! }

    let(:file) { "valid.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { process! }
        .to change(class_import, :processed_at).from(nil)
        .and change(class_import.patients, :count).by(4)
        .and change(class_import.parents, :count).by(3)
        .and change(team.cohorts, :count).by(1)

      expect(Cohort.first).to have_attributes(
        patients: Patient.all,
        birth_academic_year: 2009
      )

      expect(Patient.first).to have_attributes(
        nhs_number: "1234567890",
        date_of_birth: Date.new(2010, 1, 1),
        full_name: "Jennifer Clarke",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        recorded_at: nil
      )

      expect(Patient.first.parents).to be_empty

      expect(Patient.second).to have_attributes(
        nhs_number: "1234567891",
        date_of_birth: Date.new(2010, 1, 2),
        full_name: "Jimmy Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        recorded_at: nil
      )

      expect(Patient.second.parents.count).to eq(1)

      expect(Patient.second.parents.first).to have_attributes(
        name: "John Smith",
        phone: "07412345678",
        email: "john@example.com",
        recorded_at: nil
      )

      expect(Patient.second.parent_relationships.first).to be_father

      expect(Patient.third).to have_attributes(
        nhs_number: "1234567892",
        date_of_birth: Date.new(2010, 1, 3),
        full_name: "Mark Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        recorded_at: nil
      )

      expect(Patient.third.parents.count).to eq(2)

      expect(Patient.third.parents.first).to have_attributes(
        name: "Jane Doe",
        phone: "07412345679",
        email: "jane@example.com",
        recorded_at: nil
      )

      expect(Patient.third.parents.second).to have_attributes(
        name: "Richard Doe",
        phone: nil,
        email: "richard@example.com",
        recorded_at: nil
      )

      expect(Patient.third.parent_relationships.first).to be_mother
      expect(Patient.third.parent_relationships.second).to be_father

      expect(Patient.fourth).to have_attributes(
        nhs_number: nil,
        date_of_birth: Date.new(2010, 1, 4),
        full_name: "Amy Nichols",
        school: location,
        address_line_1: nil,
        address_town: nil,
        address_postcode: nil,
        recorded_at: nil
      )

      expect(Patient.fourth.parents).to be_empty

      # Second import should not duplicate the patients if they're identical.

      # stree-ignore
      expect { class_import.process! }
        .to not_change(class_import, :processed_at)
        .and not_change(Patient, :count)
        .and not_change(Parent, :count)
        .and not_change(Cohort, :count)
    end

    it "stores statistics on the import" do
      # stree-ignore
      expect { process! }
        .to change(class_import, :exact_duplicate_record_count).to(0)
        .and change(class_import, :new_record_count).to(4)
        .and change(class_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      build(:class_import, csv:, team:, session:).record!
      csv.rewind

      process!
      expect(class_import.exact_duplicate_record_count).to eq(4)
    end

    context "with an existing patient matching the name" do
      before do
        create(
          :patient,
          first_name: "Jimmy",
          last_name: "Smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(3)
      end
    end

    context "with an existing patient in a different session" do
      let(:different_session) { create(:session, programme:) }

      let(:patient) do
        create(:patient, nhs_number: "1234567890", session: different_session)
      end

      it "removes the child from the original session and adds them to the new one" do
        expect(patient.upcoming_sessions).to contain_exactly(different_session)
        expect { process! }.to change { patient.reload.school }.to(
          session.location
        )
        expect(patient.upcoming_sessions).to contain_exactly(session)
      end
    end
  end

  describe "#record!" do
    subject(:record!) { class_import.record! }

    let(:file) { "valid.csv" }

    it "records the patients" do
      expect { record! }.to change(Patient.recorded, :count).from(0).to(4)
    end

    it "records the parents" do
      expect { record! }.to change(Parent.recorded, :count).from(0).to(3)
    end

    context "with an unscheduled session" do
      let(:session) do
        create(:session, :unscheduled, team:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { record! }.to change(session.patients, :count).from(0).to(4)
      end
    end

    context "with a scheduled session" do
      let(:session) do
        create(:session, :scheduled, team:, programme:, location:)
      end

      it "adds the patients to the session" do
        expect { record! }.to change(session.patients, :count).from(0).to(4)
      end
    end

    context "with a completed session" do
      let(:session) do
        create(:session, :completed, team:, programme:, location:)
      end

      it "doesn't add the patients to the session" do
        expect { record! }.not_to change(PatientSession, :count)
      end
    end

    context "with an existing patient not in the class list" do
      let(:existing_patient) { create(:patient, session:) }

      it "moves the existing patient to an unknown school" do
        expect(session.patients).to include(existing_patient)
        expect { record! }.to change { existing_patient.reload.school }.to(nil)
        expect(session.reload.patients).not_to include(existing_patient)
      end
    end
  end
end
