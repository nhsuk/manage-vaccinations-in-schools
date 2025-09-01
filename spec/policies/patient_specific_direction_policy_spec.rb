# frozen_string_literal: true

describe PatientSpecificDirectionPolicy do
  subject(:policy) { described_class.new(user, PatientSpecificDirection) }

  describe "#create?" do
    subject(:create?) { policy.create? }

    context "when user is a nurse" do
      let(:user) { build(:user, :nurse) }

      it { should be(true) }
    end

    context "when user is a prescriber" do
      let(:user) { build(:user, :prescriber) }

      it { should be(true) }
    end

    context "when user is a healthcare assistant" do
      let(:user) { build(:user, :healthcare_assistant) }

      it { should be(false) }
    end
  end
end
