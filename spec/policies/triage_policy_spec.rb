# frozen_string_literal: true

describe TriagePolicy do
  describe "Scope#resolve" do
    subject { TriagePolicy::Scope.new(user, Triage).resolve }

    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }

    let(:organisation_batch) { create(:triage, organisation:) }
    let(:non_organisation_batch) { create(:triage) }

    it { should include(organisation_batch) }
    it { should_not include(non_organisation_batch) }
  end
end
