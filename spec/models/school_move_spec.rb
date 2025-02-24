# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id              :bigint           not null, primary key
#  home_educated   :boolean
#  source          :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  patient_id      :bigint           not null
#  school_id       :bigint
#
# Indexes
#
#  idx_on_patient_id_home_educated_organisation_id_7c1b5f5066  (patient_id,home_educated,organisation_id) UNIQUE
#  index_school_moves_on_organisation_id                       (organisation_id)
#  index_school_moves_on_patient_id                            (patient_id)
#  index_school_moves_on_patient_id_and_school_id              (patient_id,school_id) UNIQUE
#  index_school_moves_on_school_id                             (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
describe SchoolMove do
  describe "validations" do
    context "to a school" do
      subject(:school_move) { build(:school_move, :to_school) }

      it { should be_valid }
    end

    context "to home schooled" do
      subject(:school_move) { build(:school_move, :to_home_educated) }

      it { should be_valid }
    end

    context "to an unknown school" do
      subject(:school_move) { build(:school_move, :to_unknown_school) }

      it { should be_valid }
    end
  end

  describe "#confirm!" do
    subject(:confirm!) { school_move.confirm!(user:) }

    let(:user) { create(:user) }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:generic_clinic_session) { organisation.generic_clinic_session }

    shared_examples "creates a log entry" do
      it "creates a log entry" do
        expect { confirm! }.to change(
          patient.school_move_log_entries,
          :count
        ).by(1)

        expect(SchoolMoveLogEntry.last).to have_attributes(
          school: school_move.school,
          home_educated: school_move.home_educated,
          user:
        )
      end
    end

    shared_examples "sets the patient school" do
      it "sets the patient school" do
        expect { confirm! }.to change(patient, :school).to(school)
        expect(patient.home_educated).to be_nil
      end
    end

    shared_examples "sets the patient to home-schooled" do
      it "sets the patient to home-schooled" do
        expect { confirm! }.to change(patient, :home_educated).to(true)
        expect(patient.school).to be_nil
      end
    end

    shared_examples "sets the patient cohort" do
      it "sets the patient cohort" do
        expect { confirm! }.to change(patient, :organisation).from(nil)
        expect(patient.organisation).to eq(organisation)
      end
    end

    shared_examples "keeps the patient cohort" do
      it "keeps the patient cohort" do
        expect { confirm! }.not_to change(patient, :organisation)
      end
    end

    shared_examples "changes the patient cohort" do
      it "changes the patient cohort" do
        expect { confirm! }.to change(patient, :organisation)
        expect(patient.organisation).to eq(new_organisation)
      end
    end

    shared_examples "adds the patient to the new school session" do
      it "adds the patient to the new school session" do
        expect(patient.sessions).not_to include(new_session)
        confirm!
        expect(patient.reload.sessions).to include(new_session)
      end
    end

    shared_examples "keeps the patient in the old school session" do
      it "keeps the patient in the old school session" do
        expect(patient.sessions).to include(session)
        confirm!
        expect(patient.reload.sessions).to include(session)
      end
    end

    shared_examples "removes the patient from the old school session" do
      it "removes the patient from the old school session" do
        expect(patient.sessions).to include(session)
        confirm!
        expect(patient.reload.sessions).not_to include(session)
      end
    end

    shared_examples "adds the patient to the community clinics" do
      it "adds the patient to the community clinics" do
        expect(patient.sessions).not_to include(generic_clinic_session)
        confirm!
        expect(patient.reload.sessions).to include(generic_clinic_session)
      end
    end

    shared_examples "keeps the patient in the community clinics" do
      it "keeps the patient in the community clinics" do
        expect(patient.sessions).to include(generic_clinic_session)
        confirm!
        expect(patient.reload.sessions).to include(generic_clinic_session)
      end
    end

    shared_examples "removes the patient from the community clinics" do
      it "removes the patient from the community clinics" do
        expect(patient.sessions).to include(generic_clinic_session)
        confirm!
        expect(patient.reload.sessions).not_to include(generic_clinic_session)
      end
    end

    shared_examples "destroys the school move" do
      it "destroys the school move and any others" do
        other_school_move = create(:school_move, :to_school, patient:)

        expect(school_move).to be_persisted
        expect { confirm! }.to change(described_class, :count).by(-2)
        expect { school_move.reload }.to raise_error(
          ActiveRecord::RecordNotFound
        )
        expect { other_school_move.reload }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end
    end

    context "with a patient in no sessions" do
      let(:patient) { create(:patient, organisation: nil) }

      context "to a school with a scheduled session" do
        let(:school_move) do
          create(:school_move, :to_school, patient:, school:)
        end

        let(:school) { create(:school, organisation:) }
        let(:new_session) do
          create(
            :session,
            :scheduled,
            location: school,
            organisation:,
            programme:
          )
        end

        include_examples "creates a log entry"
        include_examples "sets the patient cohort"
        include_examples "sets the patient school"
        include_examples "adds the patient to the new school session"
        include_examples "destroys the school move"
      end

      context "to a school with a completed session" do
        let(:school_move) do
          create(:school_move, :to_school, patient:, school:)
        end

        let(:school) { create(:school, organisation:) }
        let(:new_session) do
          create(
            :session,
            :completed,
            location: school,
            organisation:,
            programme:
          )
        end

        include_examples "creates a log entry"
        include_examples "sets the patient cohort"
        include_examples "sets the patient school"
        include_examples "adds the patient to the new school session"
        include_examples "destroys the school move"
      end

      context "to home-schooled" do
        let(:school_move) do
          create(:school_move, :to_home_educated, organisation:, patient:)
        end

        include_examples "creates a log entry"
        include_examples "sets the patient cohort"
        include_examples "sets the patient to home-schooled"
        include_examples "adds the patient to the community clinics"
        include_examples "destroys the school move"
      end
    end

    context "with a patient in a school session" do
      let(:session) { create(:session, organisation:, programme:) }
      let(:patient) { create(:patient, session:) }

      context "and not already vaccinated" do
        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "removes the patient from the old school session"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let(:new_session) do
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "removes the patient from the old school session"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "keeps the patient cohort"
          include_examples "removes the patient from the old school session"
          include_examples "adds the patient to the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "removes the patient from the old school session"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:generic_clinic_session) do
            new_organisation.generic_clinic_session
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "changes the patient cohort"
          include_examples "removes the patient from the old school session"
          include_examples "adds the patient to the community clinics"
          include_examples "destroys the school move"
        end
      end

      context "and already vaccinated" do
        before { create(:vaccination_record, programme:, patient:, session:) }

        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the old school session"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let(:new_session) do
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the old school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the old school session"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the old school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:generic_clinic_session) do
            new_organisation.generic_clinic_session
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the old school session"
          include_examples "destroys the school move"
        end
      end
    end

    context "with a home-schooled patient" do
      let(:patient) do
        create(:patient, :home_educated, session: generic_clinic_session)
      end

      context "and not already vaccinated" do
        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          it "keeps the patient as home-schooled" do
            expect { confirm! }.not_to(change { patient.reload.home_educated })
          end

          include_examples "creates a log entry"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "removes the patient from the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:patient) do
            create(
              :patient,
              :home_educated,
              session: organisation.generic_clinic_session
            )
          end
          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:generic_clinic_session) do
            new_organisation.generic_clinic_session
          end

          it "keeps the patient as home-schooled" do
            expect { confirm! }.not_to(change { patient.reload.home_educated })
          end

          include_examples "creates a log entry"
          include_examples "changes the patient cohort"
          include_examples "adds the patient to the community clinics"
          include_examples "destroys the school move"
        end
      end

      context "and already vaccinated" do
        before do
          create(
            :vaccination_record,
            programme:,
            patient:,
            session: generic_clinic_session,
            location_name: "A clinic"
          )
        end

        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          it "keeps the patient as home-schooled" do
            expect { confirm! }.not_to(change { patient.reload.home_educated })
          end

          include_examples "keeps the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:patient) do
            create(
              :patient,
              :home_educated,
              session: organisation.generic_clinic_session
            )
          end
          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end

          it "keeps the patient as home-schooled" do
            expect { confirm! }.not_to(change { patient.reload.home_educated })
          end

          include_examples "creates a log entry"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end
      end
    end

    context "with a patient in an unknown school" do
      let(:patient) do
        create(:patient, school: nil, session: generic_clinic_session)
      end

      context "and not already vaccinated" do
        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient in the community clinics"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient in the community clinics"
          include_examples "adds the patient to the new school session"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "removes the patient from the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:patient) do
            create(
              :patient,
              school: nil,
              session: organisation.generic_clinic_session
            )
          end
          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:generic_clinic_session) do
            new_organisation.generic_clinic_session
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "changes the patient cohort"
          include_examples "adds the patient to the community clinics"
          include_examples "destroys the school move"
        end
      end

      context "and already vaccinated" do
        before do
          create(
            :vaccination_record,
            programme:,
            patient:,
            session: generic_clinic_session,
            location_name: "A clinic"
          )
        end

        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :scheduled,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, organisation:) }
          let!(:new_session) do # rubocop:disable RSpec/LetSetup
            create(
              :session,
              :completed,
              location: school,
              organisation:,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, organisation:, patient:)
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to a school in a different organisation" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end
          let(:school) { create(:school, organisation: new_organisation) }
          let(:new_session) do
            create(
              :session,
              :scheduled,
              location: school,
              organisation: new_organisation,
              programme:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end

        context "to home-schooled in a different organisation" do
          let(:school_move) do
            create(
              :school_move,
              :to_home_educated,
              organisation: new_organisation,
              patient:
            )
          end

          let(:patient) do
            create(
              :patient,
              school: nil,
              session: organisation.generic_clinic_session
            )
          end
          let(:new_organisation) do
            create(:organisation, programmes: [programme])
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "changes the patient cohort"
          include_examples "keeps the patient in the community clinics"
          include_examples "destroys the school move"
        end
      end
    end
  end

  describe "#ignore!" do
    subject(:ignore!) { school_move.ignore! }

    let(:patient) { create(:patient) }

    shared_examples "an ignored school move" do
      it "doesn't change the patient's school" do
        expect { ignore! }.not_to change(patient, :school)
      end

      it "doesn't change the patient's home educated status" do
        expect { ignore! }.not_to change(patient, :home_educated)
      end

      it "destroys the school move" do
        expect(school_move).to be_persisted
        expect { ignore! }.to change(described_class, :count).by(-1)
        expect { school_move.reload }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end

      it "doesn't create a log entry" do
        expect { ignore! }.not_to change(SchoolMoveLogEntry, :count)
      end
    end

    context "to a school" do
      let(:school_move) { create(:school_move, :to_school, patient:) }

      it_behaves_like "an ignored school move"
    end

    context "to home schooled" do
      let(:school_move) { create(:school_move, :to_home_educated, patient:) }

      it_behaves_like "an ignored school move"
    end

    context "to an unknown school" do
      let(:school_move) { create(:school_move, :to_unknown_school, patient:) }

      it_behaves_like "an ignored school move"
    end
  end
end
