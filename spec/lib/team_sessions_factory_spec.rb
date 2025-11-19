# frozen_string_literal: true

describe TeamSessionsFactory do
  describe "#call" do
    subject(:call) { described_class.call(team, academic_year:) }

    let(:programmes) { [Programme.hpv] }
    let(:team) { create(:team, programmes:) }
    let(:academic_year) { AcademicYear.current }

    context "with a school that's eligible for the programme" do
      let!(:location) { create(:school, :secondary, team:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change { team.reload.sessions.count }.by(1)

        session =
          team
            .sessions
            .includes(:location, :session_programme_year_groups)
            .first
        expect(session.location).to eq(location)
        expect(session.programmes).to eq(programmes)
      end
    end

    context "with a generic clinic" do
      let!(:location) { create(:generic_clinic, team:) }

      it "creates missing unscheduled sessions" do
        expect { call }.to change(team.sessions, :count).by(1)

        session =
          team
            .sessions
            .includes(:location, :session_programme_year_groups)
            .first
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
            programmes: [Programme.flu]
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
      let(:doubles_programmes) { [Programme.menacwy, Programme.td_ipv] }
      let(:flu_programmes) { [Programme.flu] }
      let(:hpv_programmes) { [Programme.hpv] }

      let(:programmes) { flu_programmes + hpv_programmes + doubles_programmes }

      context "with a generic clinic that's eligible for the programmes" do
        let!(:location) { create(:generic_clinic, team:) }

        it "creates missing unscheduled sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(1)

          session =
            team
              .sessions
              .includes(:session_programme_year_groups, :team_location)
              .order(:created_at)
              .last

          expect(session.location_id).to eq(location.id)
          expect(session.programmes).to match_array(programmes)
        end
      end

      context "with a school that's eligible for the programmes" do
        let!(:location) { create(:school, :secondary, team:) }

        it "creates missing unscheduled sessions for each programme group" do
          expect { call }.to change(team.sessions, :count).by(3)

          sessions =
            team
              .sessions
              .includes(:session_programme_year_groups, :team_location)
              .order(:created_at)

          expect(sessions.first.programmes).to eq(flu_programmes)
          expect(sessions.first.location_id).to eq(location.id)
          expect(sessions.second.programmes).to eq(hpv_programmes)
          expect(sessions.second.location_id).to eq(location.id)
          expect(sessions.third.programmes).to eq(doubles_programmes)
          expect(sessions.third.location_id).to eq(location.id)
        end
      end
    end
  end
end
