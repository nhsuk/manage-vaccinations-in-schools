# frozen_string_literal: true

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:users_team) { create :team }
    let(:another_team) { create :team }
    let(:user) { create :user, teams: [users_team] }
    let(:users_teams_session) { create :session, team: users_team }
    let(:another_teams_session) { create :session, team: another_team }

    it { should include users_teams_session }
    it { should_not include another_teams_session }
  end
end
