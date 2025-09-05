# frozen_string_literal: true

describe GillickAssessmentPolicy do
  subject(:policy) { described_class.new(user, GillickAssessment) }

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
end
