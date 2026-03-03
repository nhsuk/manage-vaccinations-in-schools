# frozen_string_literal: true

describe BatchPolicy do
  describe "Scope#resolve" do
    subject { BatchPolicy::Scope.new(user, Batch).resolve }

    let(:team) { create(:team) }
    let(:user) { create(:user, team:) }

    let(:vaccine) { Vaccine.all.sample }

    let(:batch) { create(:batch, team:, vaccine:) }
    let(:archived_batch) { create(:batch, :archived, team:, vaccine:) }
    let(:non_team_batch) { create(:batch, vaccine:) }

    it { should include(batch) }
    it { should include(archived_batch) }
    it { should_not include(non_team_batch) }
  end
end
