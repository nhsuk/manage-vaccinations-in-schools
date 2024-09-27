# frozen_string_literal: true

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:programme) { create(:programme) }
    let(:team) { create(:team, programmes: [programme]) }
    let(:user) { create(:user, teams: [team]) }

    let(:users_teams_session) { create(:session, team:, programme:) }
    let(:another_teams_session) { create(:session) }

    it { should include(users_teams_session) }
    it { should_not include(another_teams_session) }
  end
end
