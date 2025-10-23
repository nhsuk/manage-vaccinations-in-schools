# frozen_string_literal: true

describe CommitPatientChangesetsJob do
  subject(:perform_job) { described_class.perform_now(import) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:team) { create(:team, :with_generic_clinic, programmes:) }
  let(:location) { create(:school, team:) }
  let(:session) { create(:session, location:, programmes:, team:) }

  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/class_import/#{file}") }
  let(:import) { create(:class_import, csv:, session:, team:) }

  before do
    import.load_data!
    import.parse_rows!
    import.rows.each_with_index.map do |row, row_number|
      PatientChangeset.from_import_row(row:, import:, row_number:)
    end
    import.save!
  end

  describe "#perform" do
    context "when import_low_pds_match_rate flag is disabled" do
      before { Flipper.disable(:import_low_pds_match_rate) }

      it "updates the status of the import to processed" do
        perform_job

        expect(import.reload.status).to eq("processed")
      end

      it "creates patients, parents, and relationships with correct data" do
        perform_job

        jennifer = Patient.find_by!(nhs_number: "9990000018")

        expect(jennifer).to have_attributes(
          date_of_birth: Date.new(2010, 1, 1),
          given_name: "Jennifer",
          family_name: "Clarke",
          school: location,
          address_line_1: "10 Downing Street",
          address_town: "London",
          address_postcode: "SW1A 1AA",
          birth_academic_year: 2011
        )

        expect(jennifer.parents.count).to eq(1)
        expect(jennifer.parents.first).to have_attributes(
          full_name: nil,
          phone: "07412 345678",
          email: "susan@example.com"
        )

        jimmy = Patient.find_by!(nhs_number: "9990000026")

        expect(jimmy).to have_attributes(
          date_of_birth: Date.new(2010, 1, 2),
          given_name: "Jimmy",
          family_name: "Smith",
          school: location,
          address_line_1: "10 Downing Street",
          address_town: "London",
          address_postcode: "SW1A 1AA",
          birth_academic_year: 2009
        )

        expect(jimmy.parents.count).to eq(1)
        expect(jimmy.parents.first).to have_attributes(
          full_name: "John Smith",
          phone: "07412 345678",
          email: "john@example.com"
        )
        expect(jimmy.parent_relationships.first).to be_father

        mark = Patient.find_by!(nhs_number: "9990000034")

        expect(mark).to have_attributes(
          date_of_birth: Date.new(2010, 1, 3),
          given_name: "Mark",
          family_name: "Doe",
          school: location,
          address_line_1: "11 Downing Street",
          address_town: "London",
          address_postcode: "SW1A 1AA",
          birth_academic_year: 2009
        )

        expect(mark.parents.count).to eq(2)

        jane =
          mark
            .parents
            .includes(:parent_relationships)
            .find_by!(email: "jane@example.com")
        expect(jane).to have_attributes(
          full_name: "Jane Doe",
          phone: "07412 345679"
        )
        expect(jane.parent_relationships.first).to be_mother

        richard =
          mark
            .parents
            .includes(:parent_relationships)
            .find_by!(email: "richard@example.com")
        expect(richard).to have_attributes(full_name: "Richard Doe", phone: nil)
        expect(richard.parent_relationships.first).to be_father

        gae = Patient.find_by!(given_name: "Gae", family_name: "Thorne-Smith")

        expect(gae).to have_attributes(
          nhs_number: nil,
          date_of_birth: Date.new(2010, 4, 9),
          school: location,
          address_line_1: nil,
          address_town: nil,
          address_postcode: nil,
          birth_academic_year: 2009
        )

        expect(gae.parents).not_to be_empty
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { perform_job }
          .to change(import, :exact_duplicate_record_count).to(0)
          .and change(import, :new_record_count).to(4)
          .and change(import, :changed_record_count).to(0)
      end

      it "enqueues a job to move aged out patients" do
        expect { perform_job }.to have_enqueued_job(
          PatientsAgedOutOfSchoolJob
        ).once
      end

      it "imports PDS search results when present" do
        changeset = import.changesets.first
        changeset.pending_changes["search_results"] = [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9990000018",
            "created_at" => Time.zone.now
          }
        ]
        changeset.save!

        expect { perform_job }.to change(PDSSearchResult, :count).by(1)
      end

      context "with an existing patient matching the name" do
        let!(:patient) do
          create(
            :patient,
            given_name: "Jimmy",
            family_name: "Smith",
            date_of_birth: Date.new(2010, 1, 2),
            nhs_number: nil,
            parents: []
          )
        end

        it "doesn't create an additional patient" do
          expect { perform_job }.to change(Patient, :count).by(3)
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
            expect { perform_job }.to change(Parent, :count).by(4)

            parent_relationship = patient.reload.parent_relationships.first
            expect(parent_relationship.parent_id).to eq(parent.id)
            expect(parent_relationship).to be_father
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
          expect { perform_job }.to change(Patient, :count).by(3)
        end
      end

      context "with an existing parent matching the name but a different case" do
        let!(:existing_parent) do
          create(:parent, full_name: "JOHN smith", email: "john@example.com")
        end

        it "doesn't create an additional parent" do
          expect { perform_job }.to change(Parent, :count).by(4)
        end

        it "changes the parent's name to the incoming version" do
          perform_job
          expect(existing_parent.reload.full_name).to eq("John Smith")
        end
      end

      context "with an existing patient in a session for a previous academic year but not the current" do
        let(:previous_academic_year) { session.academic_year - 1 }

        let(:patient) do
          create(
            :patient,
            nhs_number: "9990000018",
            school: location,
            session:
              create(
                :session,
                team:,
                programmes:,
                location:,
                academic_year: previous_academic_year,
                date: previous_academic_year.to_academic_year_date_range.begin
              )
          )
        end

        it "adds the patient to the upcoming session" do
          expect(patient.sessions).not_to include(session)

          expect { perform_job }.to change { patient.reload.sessions.count }.by(
            1
          )

          expect(patient.sessions).to include(session)
        end
      end

      context "with an existing patient in the same school but not in the team" do
        let(:patient) do
          create(
            :patient,
            nhs_number: "9990000018",
            school: location,
            session: create(:session, programmes:)
          )
        end

        it "adds the patient to the session" do
          expect(patient.sessions).not_to include(session)
          perform_job
          expect(patient.reload.sessions).to include(session)
        end
      end

      context "with an existing patient already in the team but in a different school" do
        let(:patient) do
          create(
            :patient,
            nhs_number: "9990000018",
            school: create(:school),
            session: create(:session, team:, programmes:)
          )
        end

        it "proposes a school move for the child" do
          expect(patient.school_moves).to be_empty

          expect { perform_job }.to change {
            patient.reload.school_moves.count
          }.by(1)

          school_move = patient.school_moves.first
          expect(school_move.school_id).to eq(session.location_id)
        end

        it "doesn't stage school changes" do
          expect { perform_job }.not_to change(patient, :pending_changes)
          expect(patient.pending_changes.keys).not_to include(
            :cohort_id,
            :home_educated,
            :team_id,
            :school_id
          )
        end
      end

      context "with an unscheduled session" do
        let(:session) do
          create(:session, :unscheduled, team:, programmes:, location:)
        end

        it "adds the patients to the session" do
          expect { perform_job }.to change(session.patients, :count).from(0).to(
            4
          )
        end
      end

      context "with a scheduled session" do
        let(:session) do
          create(:session, :scheduled, team:, programmes:, location:)
        end

        it "adds the patients to the session" do
          expect { perform_job }.to change(session.patients, :count).from(0).to(
            4
          )
        end
      end

      context "with an existing patient not in the class list" do
        let!(:existing_patient) do
          create(:patient, nhs_number: "9322774096", session:, year_group: 8)
        end

        it "proposes a school move for the child" do
          expect(existing_patient.school_moves).to be_empty

          expect { perform_job }.to change {
            existing_patient.reload.school_moves.count
          }.by(1)

          school_move = existing_patient.school_moves.first
          expect(school_move.school).to be_nil
          expect(school_move.home_educated).to be(false)
        end

        it "doesn't propose a move if patient already has a proposed move" do
          create(
            :school_move,
            :to_unknown_school,
            patient: existing_patient,
            team:
          )

          expect { perform_job }.not_to(
            change { existing_patient.reload.school_moves.count }
          )
        end

        it "doesn't propose a move if the patient is in a different year group" do
          academic_year = AcademicYear.pending

          existing_patient.update!(
            birth_academic_year: 7.to_birth_academic_year(academic_year:)
          )

          expect { perform_job }.not_to(
            change { existing_patient.reload.school_moves.count }
          )
        end
      end

      context "with an existing twin" do
        # This matches the details of the first row of `valid.csv` except the given name and registration.
        let!(:twin) do
          create(
            :patient,
            session:,
            nhs_number: nil,
            date_of_birth: Date.new(2010, 1, 1),
            given_name: "Samuel",
            preferred_given_name: nil,
            family_name: "Clarke",
            school: location,
            address_line_1: "10 Downing Street",
            address_line_2: nil,
            address_town: "London",
            address_postcode: "SW1A 1AA",
            year_group: 9,
            registration: "XYZ"
          )
        end

        it "doesn't auto-accept changes for potential twins, but queues them for manual review" do
          expect { perform_job }.to change { twin.reload.pending_changes }.from(
            {}
          ).to(
            {
              "given_name" => "Jennifer",
              "preferred_given_name" => "Jenny",
              "nhs_number" => "9990000018",
              "registration" => "ABC"
            }
          ).and not_change(twin, :given_name).and not_change(
                        twin,
                        :preferred_given_name
                      ).and not_change(twin, :nhs_number).and not_change(
                                    twin,
                                    :registration
                                  )
        end
      end
    end

    context "when import_low_pds_match_rate flag is enabled" do
      before { Flipper.enable(:import_low_pds_match_rate) }
      after { Flipper.disable(:import_low_pds_match_rate) }

      context "and import is below match rate threshold" do
        before do
          create_list(:patient_changeset, 6, :with_pds_match, import:)
          create_list(:patient_changeset, 4, import:)
          import.validate_pds_match_rate!
        end

        it "marks the import as low_pds_match_rate and stops processing" do
          expect(import).to receive(:validate_pds_match_rate!).and_call_original
          expect(import).not_to receive(:postprocess_rows!)

          perform_job
          expect(import.reload.status).to eq("low_pds_match_rate")
        end
      end

      context "and import is above match rate threshold" do
        before do
          create_list(:patient_changeset, 7, :with_pds_match, import:)
          create_list(:patient_changeset, 3, import:)
          import.validate_pds_match_rate!
        end

        it "continues processing normally" do
          expect { perform_job }.to change(Patient, :count).by(4)
          expect(import.reload.status).to eq("processed")
        end
      end
    end
  end

  describe "#import_patients_and_parents" do
    context "when patients have NHS number changes" do
      subject(:import_patients_and_parents) do
        job = described_class.new
        job.send(:import_patients_and_parents, changesets, import)
      end

      let!(:first_patient) { create(:patient) }
      let!(:second_patient) { create(:patient) }
      let!(:third_patient) { create(:patient, nhs_number: nil) }
      let(:patients) { [first_patient, second_patient, third_patient] }

      let(:changesets) do
        patients.map do |patient|
          instance_double(
            PatientChangeset,
            patient:,
            parents: [],
            parent_relationships: []
          )
        end
      end

      before do
        allow(Patient).to receive(:import)
        allow(PatientChangeset).to receive(:import)
        allow(Parent).to receive(:import)
        allow(ParentRelationship).to receive(:import)

        changesets.each do |changeset|
          allow(changeset).to receive(:assign_patient_id)
        end
      end

      context "when patients have NHS number changes" do
        before do
          allow(first_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(true)
          allow(second_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(true)
          allow(third_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
        end

        it "enqueues SearchVaccinationRecordsInNHSJob for patients with NHS number changes" do
          import_patients_and_parents

          expect(SearchVaccinationRecordsInNHSJob).to have_enqueued_sidekiq_job(
            first_patient.id
          )
          expect(SearchVaccinationRecordsInNHSJob).to have_enqueued_sidekiq_job(
            second_patient.id
          )
          expect(
            SearchVaccinationRecordsInNHSJob
          ).not_to have_enqueued_sidekiq_job(third_patient.id)
        end
      end

      context "when no patients have NHS number changes" do
        before do
          allow(first_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
          allow(second_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
          allow(third_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
        end

        it "does not enqueue SearchVaccinationRecordsInNHSJob" do
          expect { import_patients_and_parents }.not_to enqueue_sidekiq_job(
            SearchVaccinationRecordsInNHSJob
          )
        end
      end
    end
  end
end
