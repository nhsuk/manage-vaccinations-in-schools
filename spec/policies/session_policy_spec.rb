# frozen_string_literal: true

describe SessionPolicy do
  subject(:policy) { described_class.new(user, session) }

  shared_examples "edit/update session" do
    context "with an admin" do
      let(:user) { create(:admin) }

      context "with a scheduled session" do
        let(:session) { create(:session, :scheduled) }

        it { should be(true) }
      end

      context "with an unscheduled session" do
        let(:session) { create(:session, :unscheduled) }

        it { should be(true) }
      end
    end

    context "with a nurse" do
      let(:user) { create(:nurse) }

      context "with a scheduled session" do
        let(:session) { create(:session, :scheduled) }

        it { should be(true) }
      end

      context "with an unscheduled session" do
        let(:session) { create(:session, :unscheduled) }

        it { should be(true) }
      end
    end
  end

  describe "#edit?" do
    subject(:edit?) { policy.edit? }

    include_examples "edit/update session"
  end

  describe "#update?" do
    subject(:update?) { policy.update? }

    include_examples "edit/update session"
  end

  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:user) { create(:user, organisation:) }

    let(:users_organisations_session) do
      create(:session, organisation:, programme:)
    end
    let(:another_organisations_session) { create(:session, programme:) }

    it { should include(users_organisations_session) }
    it { should_not include(another_organisations_session) }
  end
end
