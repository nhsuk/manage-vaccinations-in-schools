# frozen_string_literal: true

describe InspectPolicy do
  subject(:policy) { described_class.new(user, :inspect) }

  let(:support_team) { create(:team, :support) }

  describe "#dashboard?" do
    subject(:dashboard?) { policy.dashboard? }

    context "with a support user on a support team" do
      let(:user) { create(:support, team: support_team) }

      it { should be(true) }
    end

    context "with a nurse on a point_of_care team" do
      let(:user) { create(:nurse) }

      it { should be(false) }
    end

    context "with a support user on a point_of_care team" do
      let(:user) { create(:support) }

      it { should be(false) }
    end
  end

  describe "#graph?" do
    subject(:graph?) { policy.graph? }

    context "with a support user on a support team" do
      let(:user) { create(:support, team: support_team) }

      it { should be(true) }
    end

    context "with a nurse on a point_of_care team" do
      let(:user) { create(:nurse) }

      it { should be(false) }
    end
  end

  describe "#timeline?" do
    subject(:timeline?) { policy.timeline? }

    context "with a support user on a support team" do
      let(:user) { create(:support, team: support_team) }

      it { should be(true) }
    end

    context "with a nurse on a point_of_care team" do
      let(:user) { create(:nurse) }

      it { should be(false) }
    end
  end

  describe "#show_pii?" do
    subject(:show_pii?) { policy.show_pii? }

    context "with a support user with PII access on a support team" do
      let(:user) { create(:support, team: support_team) }

      it { should be(true) }
    end

    context "with a support user without PII access on a support team" do
      let(:user) do
        create(
          :support,
          team: support_team,
          activity_codes: [
            CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
          ]
        )
      end

      it { should be(false) }
    end

    context "with a nurse on a point_of_care team" do
      let(:user) { create(:nurse) }

      it { should be(false) }
    end
  end
end
