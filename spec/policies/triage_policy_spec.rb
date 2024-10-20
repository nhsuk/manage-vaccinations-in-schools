# frozen_string_literal: true

describe TriagePolicy do
  describe "Scope#resolve" do
    subject { TriagePolicy::Scope.new(user, Triage).resolve }

    let(:team) { create(:team) }
    let(:user) { create(:user, teams: [team]) }

    let(:team_batch) { create(:triage, team:) }
    let(:non_team_batch) { create(:triage) }

    it { should include(team_batch) }
    it { should_not include(non_team_batch) }
  end
end
