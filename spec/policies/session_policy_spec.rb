# frozen_string_literal: true

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:team) { create(:team) }
    let(:user) { create(:user, teams: [team]) }

    let(:users_teams_session) do
      create(:session, programme: create(:programme, team:))
    end
    let(:another_teams_session) { create(:session) }

    it { should include(users_teams_session) }
    it { should_not include(another_teams_session) }
  end
end
