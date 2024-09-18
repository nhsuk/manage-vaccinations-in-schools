# frozen_string_literal: true

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:users_team) { create :team }
    let(:another_team) { create :team }
    let(:user) { create :user, teams: [users_team] }
    let(:users_teams_programme) { create :programme, team: users_team }
    let(:another_teams_programme) { create :programme, team: another_team }
    let(:users_teams_session) do
      create :session, programme: users_teams_programme
    end
    let(:another_teams_session) do
      create :session, programme: another_teams_programme
    end

    it { should include users_teams_session }
    it { should_not include another_teams_session }
  end

  describe "DraftScope#resolve" do
    subject { SessionPolicy::DraftScope.new(user, Session).resolve }

    let(:team) { create :team }
    let(:user) { create :user, teams: [team] }
    let(:location) { create(:location, :school) }
    let(:programme) { create :programme, team: }
    let(:draft_session) { create :session, :draft, location:, programme: }
    let(:session) { create :session, location:, programme: }

    it { should include draft_session }
    it { should_not include session }

    context "location and programme are nil" do
      let(:draft_session) do
        create :session, :draft, location: nil, programme: nil
      end

      it { should include draft_session }
    end

    context "programme is set but not location" do
      let(:draft_session) { create :session, :draft, location: nil, programme: }

      it { should include draft_session }
    end
  end
end
