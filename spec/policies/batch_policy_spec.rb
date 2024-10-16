# frozen_string_literal: true

describe BatchPolicy do
  describe "Scope#resolve" do
    subject { BatchPolicy::Scope.new(user, Batch).resolve }

    let(:team) { create(:team) }
    let(:user) { create(:user, teams: [team]) }

    let(:archived_batch) { create(:batch, :archived, team:) }
    let(:unarchived_batch) { create(:batch, team:) }
    let(:non_team_batch) { create(:batch) }

    it { should include(unarchived_batch) }
    it { should_not include(archived_batch) }
    it { should_not include(non_team_batch) }
  end
end
