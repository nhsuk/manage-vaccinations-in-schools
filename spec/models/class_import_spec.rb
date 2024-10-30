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
#  recorded_at                  :datetime
#  rows_count                   :integer
#  serialized_errors            :json
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  session_id                   :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_organisation_id      (organisation_id)
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (session_id => sessions.id)
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

    describe "with minimal fields" do
      let(:file) { "valid_minimal.csv" }

      it "is valid" do
        expect(class_import).to be_valid
        expect(class_import.rows.count).to eq(1)
        expect(class_import.rows.first.to_patient).to have_attributes(
          given_name: "Jennifer",
          family_name: "Clarke",
          date_of_birth: Date.new(2010, 1, 1),
          school: location
        )
      end
    end
  end

  describe "#record!" do
    subject(:record!) { class_import.record! }

    let(:file) { "valid.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { record! }
        .to change(class_import, :recorded_at).from(nil)
        .and change(class_import.patients, :count).by(4)
        .and change(class_import.parents, :count).by(5)
        .and change(team.cohorts, :count).by(1)

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

      expect(Patient.first.parents.count).to eq(1)

      expect(Patient.first.parents.first).to have_attributes(
        full_name: nil,
        phone: "07412345678",
        email: "susan@example.com"
      )

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
        nhs_number: "1234567892",
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

      expect(Patient.third.parents.second).to have_attributes(
        full_name: "Richard Doe",
        phone: nil,
        email: "richard@example.com"
      )

      expect(Patient.third.parent_relationships.first).to be_mother
      expect(Patient.third.parent_relationships.second).to be_father

      expect(Patient.fourth).to have_attributes(
        nhs_number: nil,
        date_of_birth: Date.new(2010, 4, 9),
        full_name: "Gae Thorne-Smith",
        school: location,
        address_line_1: nil,
        address_town: nil,
        address_postcode: "SW1A 1AA"
      )

      expect(Patient.fourth.parents).not_to be_empty

      # Second import should not duplicate the patients if they're identical.

      # stree-ignore
      expect { class_import.record! }
        .to not_change(class_import, :recorded_at)
        .and not_change(Patient, :count)
        .and not_change(Parent, :count)
        .and not_change(Cohort, :count)
    end

    it "stores statistics on the import" do
      # stree-ignore
      expect { record! }
        .to change(class_import, :exact_duplicate_record_count).to(0)
        .and change(class_import, :new_record_count).to(4)
        .and change(class_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      create(:class_import, csv:, team:, session:).record!
      csv.rewind

      record!
      expect(class_import.exact_duplicate_record_count).to eq(4)
    end

    it "enqueues jobs to look up missing NHS numbers" do
      expect { record! }.to have_enqueued_job(
        PatientNHSNumberLookupJob
      ).once.on_queue(:imports)
    end

    it "enqueues jobs to update from PDS" do
      expect { record! }.to have_enqueued_job(PatientUpdateFromPDSJob)
        .exactly(3)
        .times
        .on_queue(:imports)
    end

    context "with an existing patient matching the name" do
      let!(:patient) do
        create(
          :patient,
          given_name: "Jimmy",
          family_name: "Smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { record! }.to change(Patient, :count).by(3)
      end

      context "with an existing parent" do
        let!(:parent) do
          create(
            :parent,
            full_name: "John Smith",
            email: "john@example.com",
            phone: "07412345678"
          )
        end

        it "doesn't create an additional patient" do
          expect { record! }.to change(Parent, :count).by(4)
          expect(parent.relationship_to(patient:)).to be_father
        end
      end
    end

    context "with an existing patient matching the name but a different case" do
      before do
        create(
          :patient,
          given_name: "jimmy",
          family_name: "SMITH",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { record! }.to change(Patient, :count).by(3)
      end
    end

    context "with an existing patient in a different session" do
      let(:different_session) { create(:session, programme:) }

      let(:patient) do
        create(:patient, nhs_number: "1234567890", session: different_session)
      end

      it "proposes moving the child from the original session to the new one" do
        expect(patient.upcoming_sessions).to contain_exactly(different_session)

        # stree-ignore
        expect { record! }
          .to change { patient.patient_sessions
            .find_by(session: different_session)
            .proposed_session }.from(nil).to(session)

        expect(patient.upcoming_sessions).to contain_exactly(different_session)
      end

      it "stages changes to the child's cohort" do
        expect(patient.cohort.team).to eq(different_session.team)
        expect { record! }.to(
          change { patient.reload.with_pending_changes.cohort }
        )
        expect(patient.with_pending_changes.cohort.team).to eq(session.team)
      end
    end

    it "records the parents" do
      expect { record! }.to change(Parent.recorded, :count).from(0).to(5)
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

    context "with a closed session" do
      let(:session) { create(:session, :closed, team:, programme:, location:) }

      it "doesn't add the patients to the session" do
        expect { record! }.not_to change(PatientSession, :count)
      end
    end

    context "with an existing patient not in the class list" do
      let!(:existing_patient) { create(:patient, session:) }

      it "proposes moving the existing patient to the generic clinic" do
        location = create(:location, :generic_clinic, team:)
        generic_clinic_session = create(:session, location:, team:, programme:)

        expect(session.patients).to include(existing_patient)
        expect(generic_clinic_session.patients).to be_empty

        record!

        expect(session.reload.patients).to include(existing_patient)
        expect(generic_clinic_session.patients).to be_empty
        expect(
          session.patient_sessions_moving_from_this_session.map(&:patient)
        ).to include(existing_patient)
        expect(
          generic_clinic_session.patient_sessions_moving_to_this_session.map(
            &:patient
          )
        ).to include(existing_patient)
      end

      it "doesn't propose a move if patient already has a proposed move" do
        existing_session = create(:session, team:, programme:)

        existing_patient_session =
          PatientSession.find_by!(patient: existing_patient, session:)
        existing_patient_session.update!(proposed_session: existing_session)

        expect { record! }.not_to(
          change { existing_patient_session.reload.proposed_session }
        )
      end
    end
  end
end
