# frozen_string_literal: true

describe TeamSessionsFactory do
  describe "#call" do
    subject(:call) { described_class.call(team, academic_year:) }

    let(:programmes) { [CachedProgramme.hpv] }
    let(:team) { create(:team, programmes:) }
    let(:academic_year) { AcademicYear.current }

    context "with a school that's eligible for the programme" do
      let!(:location) { create(:school, :secondary, team:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(team.sessions, :count).by(1)

        session = team.sessions.includes(:location).first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq(programmes)
      end
    end

    context "with a generic clinic" do
      let!(:location) { create(:generic_clinic, team:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(team.sessions, :count).by(1)

        session = team.sessions.includes(:location).first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq(programmes)
      end

      context "if a session already exists" do
        let!(:session) do
          create(
            :session,
            :unscheduled,
            location:,
            team:,
            programmes: [CachedProgramme.flu]
          )
        end

        it "adds the programmes to the existing session" do
          expect { call }.not_to change(team.sessions, :count)

          expect(session.reload.programme_types).to include(
            *programmes.map(&:type)
          )
        end
      end
    end

    context "with a community clinic" do
      before { create(:community_clinic, team:) }

      it "doesn't create any unscheduled sessions" do
        expect { call }.not_to change(team.sessions, :count)
      end
    end

    context "with a school that's not eligible for the programme" do
      before { create(:school, :primary, team:) }

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session already exists" do
      before do
        location = create(:school, :secondary, team:)
        create(:session, team:, location:, programmes:)
      end

      it "doesn't create any sessions" do
        expect { call }.not_to change(Session, :count)
      end
    end

    context "when a session exists for a different academic year" do
      before do
        location = create(:school, :secondary, team:)
        create(
          :session,
          team:,
          location:,
          programmes:,
          date: Date.new(2013, 1, 1)
        )
      end

      it "creates the missing unscheduled session" do
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

        it "creates missing unscheduled sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(1)

          session = team.sessions.includes(:location).find_by(location:)
          expect(session.programmes).to match_array(programmes)
        end
      end

      context "with a school that's eligible for the programmes" do
        let!(:location) { create(:school, :secondary, team:) }

        it "creates missing unscheduled sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(3)

          session = team.sessions.order(:created_at).where(location:)
          expect(session.first.programmes).to eq(flu_programmes)
          expect(session.second.programmes).to eq(hpv_programmes)
          expect(session.third.programmes).to eq(doubles_programmes)
        end
      end
    end

    context "with an unscheduled session for a location no longer managed by the team" do
      let(:location) { create(:school, :secondary) }
      let!(:session) do
        create(:session, :unscheduled, team:, location:, programmes:)
      end

      it "destroys the session" do
        expect { call }.to change(Session, :count).by(-1)
        expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a scheduled session for a location no longer managed by the team" do
      let(:location) { create(:school, :secondary) }

      before { create(:session, :scheduled, team:, location:, programmes:) }

      it "doesn't destroy the session" do
        expect { call }.not_to change(Session, :count)
      end
    end
  end
end
