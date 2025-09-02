# frozen_string_literal: true

describe PatientSpecificDirectionPolicy do
  subject(:policy) { described_class.new(user, PatientSpecificDirection) }

  describe "#create?" do
    subject { policy.create? }

    context "when user is a nurse" do
      let(:user) { build(:nurse) }

      it { should be(false) }
    end

    context "when user is a prescriber" do
      let(:user) { build(:prescriber) }

      it { should be(true) }
    end

    context "when user is a healthcare assistant" do
      let(:user) { build(:healthcare_assistant) }

      it { should be(false) }
    end
  end
end
