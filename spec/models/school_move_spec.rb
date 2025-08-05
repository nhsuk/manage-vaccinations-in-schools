# frozen_string_literal: true

# == Schema Information
#
# Table name: school_moves
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  home_educated :boolean
#  source        :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  patient_id    :bigint           not null
#  school_id     :bigint
#  team_id       :bigint
#
# Indexes
#
#  index_school_moves_on_patient_id_and_home_educated_and_team_id  (patient_id,home_educated,team_id) UNIQUE
#  index_school_moves_on_patient_id_and_school_id                  (patient_id,school_id) UNIQUE
#  index_school_moves_on_school_id                                 (school_id)
#  index_school_moves_on_team_id                                   (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#  fk_rails_...  (team_id => teams.id)
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

    let(:today) { nil }
    let(:user) { create(:user) }
    let(:programmes) { [create(:programme)] }
    let(:team) { create(:team, :with_generic_clinic, programmes:) }
    let(:generic_clinic_session) { team.generic_clinic_session(academic_year:) }

    around { |example| travel_to(today) { example.run } }

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

    shared_examples "adds the patient to the new school sessions" do
      it "adds the patient to the new school sessions" do
        expect(patient.sessions).not_to include(*new_sessions)
        confirm!
        expect(patient.reload.sessions).to include(*new_sessions)
      end
    end

    shared_examples "keeps the patient in the old school sessions" do
      it "keeps the patient in the old school sessions" do
        expect(patient.sessions).to include(session)
        confirm!
        expect(patient.reload.sessions).to include(session)
      end
    end

    shared_examples "removes the patient from the old school sessions" do
      it "removes the patient from the old school sessions" do
        expect(patient.sessions).to include(session)
        confirm!
        expect(patient.reload.sessions).not_to include(session)
      end
    end

    shared_examples "adds the patient to the community clinic" do
      it "adds the patient to the community clinic" do
        expect(patient.sessions).not_to include(generic_clinic_session)
        confirm!
        expect(patient.reload.sessions).to include(generic_clinic_session)
      end
    end

    shared_examples "keeps the patient in the community clinic" do
      it "keeps the patient in the community clinic" do
        expect(patient.sessions).to include(generic_clinic_session)
        confirm!
        expect(patient.reload.sessions).to include(generic_clinic_session)
      end
    end

    shared_examples "removes the patient from the community clinic" do
      it "removes the patient from the community clinic" do
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

    shared_examples "handles the school moves" do
      let(:academic_year) { AcademicYear.pending }

      context "with a patient in no sessions" do
        let(:patient) { create(:patient, team: nil) }

        context "to a school with a scheduled session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, team:) }
          let(:new_sessions) do
            create_list(
              :session,
              2,
              date: session_date + 1.week,
              location: school,
              team:,
              programmes:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "adds the patient to the new school sessions"
          include_examples "destroys the school move"
        end

        context "to a school with a completed session" do
          let(:school_move) do
            create(:school_move, :to_school, patient:, school:)
          end

          let(:school) { create(:school, team:) }
          let(:new_sessions) do
            create_list(
              :session,
              2,
              date: session_date - 1.week,
              location: school,
              team:,
              programmes:
            )
          end

          include_examples "creates a log entry"
          include_examples "sets the patient school"
          include_examples "adds the patient to the new school sessions"
          include_examples "destroys the school move"
        end

        context "to home-schooled" do
          let(:school_move) do
            create(:school_move, :to_home_educated, team:, patient:)
          end

          include_examples "creates a log entry"
          include_examples "sets the patient to home-schooled"
          include_examples "adds the patient to the community clinic"
          include_examples "destroys the school move"
        end
      end

      context "with a patient in a school session" do
        let(:session) do
          create(:session, date: session_date, team:, programmes:)
        end
        let(:patient) { create(:patient, session:) }

        context "and not already vaccinated" do
          context "to a school with a scheduled session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "removes the patient from the old school sessions"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date - 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "removes the patient from the old school sessions"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "removes the patient from the old school sessions"
            include_examples "adds the patient to the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "removes the patient from the old school sessions"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:generic_clinic_session) do
              new_team.generic_clinic_session(academic_year:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "removes the patient from the old school sessions"
            include_examples "adds the patient to the community clinic"
            include_examples "destroys the school move"
          end
        end

        context "and already vaccinated" do
          before do
            create(
              :vaccination_record,
              patient:,
              session:,
              programme: programmes.first
            )
          end

          context "to a school with a scheduled session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the old school sessions"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date - 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the old school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "keeps the patient in the old school sessions"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the old school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:generic_clinic_session) do
              new_team.generic_clinic_session(
                academic_year: AcademicYear.current
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "keeps the patient in the old school sessions"
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

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date - 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            it "keeps the patient as home-schooled" do
              expect { confirm! }.not_to(
                change { patient.reload.home_educated }
              )
            end

            include_examples "creates a log entry"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "removes the patient from the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:patient) do
              create(
                :patient,
                :home_educated,
                session: team.generic_clinic_session(academic_year:)
              )
            end
            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:generic_clinic_session) do
              new_team.generic_clinic_session(academic_year:)
            end

            it "keeps the patient as home-schooled" do
              expect { confirm! }.not_to(
                change { patient.reload.home_educated }
              )
            end

            include_examples "creates a log entry"
            include_examples "adds the patient to the community clinic"
            include_examples "destroys the school move"
          end
        end

        context "and already vaccinated" do
          before do
            create(
              :vaccination_record,
              patient:,
              session: generic_clinic_session,
              programme: programmes.first,
              location_name: "A clinic"
            )
          end

          context "to a school with a scheduled session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                :completed,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            it "keeps the patient as home-schooled" do
              expect { confirm! }.not_to(
                change { patient.reload.home_educated }
              )
            end

            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:patient) do
              create(
                :patient,
                :home_educated,
                session: team.generic_clinic_session(academic_year:)
              )
            end
            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }

            it "keeps the patient as home-schooled" do
              expect { confirm! }.not_to(
                change { patient.reload.home_educated }
              )
            end

            include_examples "creates a log entry"
            include_examples "keeps the patient in the community clinic"
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

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date - 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "adds the patient to the new school sessions"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "removes the patient from the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:patient) do
              create(
                :patient,
                school: nil,
                session: team.generic_clinic_session(academic_year:)
              )
            end
            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:generic_clinic_session) do
              new_team.generic_clinic_session(academic_year:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "adds the patient to the community clinic"
            include_examples "destroys the school move"
          end
        end

        context "and already vaccinated" do
          before do
            create(
              :vaccination_record,
              patient:,
              session: generic_clinic_session,
              programme: programmes.first,
              location_name: "A clinic"
            )
          end

          context "to a school with a scheduled session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school with a completed session" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:school) { create(:school, team:) }
            let!(:new_sessions) do # rubocop:disable RSpec/LetSetup
              create_list(
                :session,
                2,
                date: session_date - 1.week,
                location: school,
                team:,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team:, patient:)
            end

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to a school in a different team" do
            let(:school_move) do
              create(:school_move, :to_school, patient:, school:)
            end

            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }
            let(:school) { create(:school, team: new_team) }
            let(:new_sessions) do
              create_list(
                :session,
                2,
                date: session_date + 1.week,
                location: school,
                team: new_team,
                programmes:
              )
            end

            include_examples "creates a log entry"
            include_examples "sets the patient school"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end

          context "to home-schooled in a different team" do
            let(:school_move) do
              create(:school_move, :to_home_educated, team: new_team, patient:)
            end

            let(:patient) do
              create(
                :patient,
                school: nil,
                session: team.generic_clinic_session(academic_year:)
              )
            end
            let(:new_team) { create(:team, :with_generic_clinic, programmes:) }

            include_examples "creates a log entry"
            include_examples "sets the patient to home-schooled"
            include_examples "keeps the patient in the community clinic"
            include_examples "destroys the school move"
          end
        end
      end
    end

    context "the day before a preparation period" do
      let(:today) { Date.new(2025, 7, 31) }

      # Create sessions in the current academic year.
      let(:session_date) { Date.new(2025, 8, 15) }

      include_examples "handles the school moves"
    end

    context "the first day of a preparation period" do
      let(:today) { Date.new(2025, 8, 1) }

      # Create sessions in the next academic year.
      let(:session_date) { Date.new(2025, 9, 15) }

      include_examples "handles the school moves"
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
