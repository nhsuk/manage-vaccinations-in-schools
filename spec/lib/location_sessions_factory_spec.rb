# frozen_string_literal: true

describe LocationSessionsFactory do
  describe "#call" do
    subject(:call) { described_class.call(location, academic_year:) }

    let(:programmes) { [CachedProgramme.hpv] }
    let(:team) { create(:team, programmes:) }
    let(:academic_year) { AcademicYear.current }

    context "with a school that's eligible for the programme" do
      let!(:location) { create(:school, :secondary, team:) }

      it "creates missing sessions" do
        expect { call }.to change(team.sessions, :count).by(1)

        session = team.sessions.includes(:location).first
        expect(session.location).to eq(location)
        expect(session.academic_year).to eq(academic_year)
        expect(session.programmes).to eq(programmes)
      end

      context "with MMR" do
        let(:programmes) { [CachedProgramme.mmr] }

        it "doesn't create a session on its own" do
          expect { call }.not_to change(team.sessions, :count)
        end
      end

      context "with patients from a previous academic year" do
        let(:previous_session_at_location) do
          create(
            :session,
            location:,
            programmes:,
            team:,
            academic_year: academic_year - 1,
            date: Date.current - 1.year
          )
        end

        let(:previous_session_at_different_location) do
          create(
            :session,
            programmes:,
            team:,
            academic_year: academic_year - 1,
            date: Date.current - 1.year
          )
        end

        let!(:patient_at_location) do
          create(
            :patient,
            school: location,
            session: previous_session_at_location
          )
        end

        let!(:patient_at_different_location) do
          create(:patient, session: previous_session_at_different_location)
        end

        it "adds the patients to the new sessions" do
          expect { call }.to change(team.sessions, :count).by(1)

          session = team.sessions.find_by(location:, academic_year:)
          expect(session.patients).to include(patient_at_location)
          expect(session.patients).not_to include(patient_at_different_location)
        end
      end
    end

    context "with a generic clinic" do
      let!(:location) { create(:generic_clinic, team:) }

      it "creates missing sessions" do
        expect { call }.to change(team.sessions, :count).by(1)

        session = team.sessions.includes(:location).first
        expect(session.location).to eq(location)
        expect(session.academic_year).to eq(academic_year)
        expect(session.programmes).to eq(programmes)
      end

      context "with patients from a previous academic year" do
        let(:previous_session_at_location) do
          create(
            :session,
            location:,
            programmes:,
            team:,
            academic_year: academic_year - 1,
            date: Date.current - 1.year
          )
        end

        let(:school) { create(:school, :secondary, team:) }

        let(:previous_session_at_school_location) do
          create(
            :session,
            location: school,
            programmes:,
            team:,
            academic_year: academic_year - 1,
            date: Date.current - 1.year
          )
        end

        let!(:patient_at_location) do
          create(:patient, school: nil, session: previous_session_at_location)
        end

        let!(:patient_at_school_location) do
          create(
            :patient,
            school:,
            session: previous_session_at_school_location
          )
        end

        it "adds the patients to the new sessions" do
          expect { call }.to change(team.sessions, :count).by(1)

          session = team.sessions.find_by(location:, academic_year:)
          expect(session.patients).to include(patient_at_location)
          expect(session.patients).not_to include(patient_at_school_location)
        end
      end
    end

    context "with a community clinic" do
      let(:location) { create(:community_clinic, team:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(team.sessions, :count)
      end
    end

    context "with a school that's not eligible for the programme" do
      let(:location) { create(:school, :primary, team:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session already exists" do
      let(:location) { create(:school, :secondary, team:) }

      before { create(:session, team:, location:, programmes:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session exists for a different academic year" do
      let(:location) { create(:school, :secondary, team:) }

      before do
        create(
          :session,
          team:,
          location:,
          programmes:,
          date: Date.new(2013, 1, 1)
        )
      end

      it "creates the missing session" do
        expect { call }.to change(team.sessions, :count).by(1)
      end
    end

    context "with all programmes" do
      let(:doubles_programmes) do
        [CachedProgramme.menacwy, CachedProgramme.td_ipv]
      end
      let(:flu_programmes) { [CachedProgramme.flu] }
      let(:hpv_programmes) { [CachedProgramme.hpv] }

      let(:programmes) { flu_programmes + hpv_programmes + doubles_programmes }

      context "with a generic clinic that's eligible for the programmes" do
        let!(:location) { create(:generic_clinic, team:) }

        it "creates missing sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(1)

          session = team.sessions.includes(:location).find_by(location:)
          expect(session.programmes).to match_array(programmes)
        end
      end

      context "with a school that's eligible for the programmes" do
        let!(:location) { create(:school, :secondary, team:) }

        it "creates missing sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(3)

          session = team.sessions.order(:created_at).where(location:)
          expect(session.first.programmes).to eq(flu_programmes)
          expect(session.second.programmes).to eq(hpv_programmes)
          expect(session.third.programmes).to eq(doubles_programmes)
        end
      end
    end
  end
end
