# frozen_string_literal: true

describe TriagePolicy do
  subject(:policy) { described_class.new(user, Triage) }

  shared_examples "only nurses or prescribers" do
    context "with a medical secretary" do
      let(:user) { create(:medical_secretary) }

      it { should be(false) }
    end

    context "with a healthcare assistant" do
      let(:user) { create(:healthcare_assistant) }

      it { should be(false) }
    end

    context "with a nurse" do
      let(:user) { create(:nurse) }

      it { should be(true) }
    end

    context "with a prescriber" do
      let(:user) { create(:prescriber) }

      it { should be(true) }
    end
  end

  describe "#new?" do
    subject { policy.new? }

    include_examples "only nurses or prescribers"
  end

  describe "#create?" do
    subject { policy.create? }

    include_examples "only nurses or prescribers"
  end

  describe "#edit?" do
    subject { policy.edit? }

    include_examples "only nurses or prescribers"
  end

  describe "#update?" do
    subject { policy.update? }

    include_examples "only nurses or prescribers"
  end

  describe TriagePolicy::Scope do
    describe "#resolve" do
      subject { described_class.new(user, Triage).resolve }

      let(:team) { create(:team) }
      let(:user) { create(:user, team:) }

      let(:triage_for_team) { create(:triage, :safe_to_vaccinate, team:) }
      let(:triage_for_different_team) do
        create(:triage, :safe_to_vaccinate, team: create(:team))
      end
      let(:triage_for_all_teams) { create(:triage, :safe_to_vaccinate) }

      it { should include(triage_for_team) }
      it { should_not include(triage_for_different_team) }
      it { should include(triage_for_all_teams) }
    end
  end
end
