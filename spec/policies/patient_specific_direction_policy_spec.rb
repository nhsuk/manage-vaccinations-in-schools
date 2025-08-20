# frozen_string_literal: true

RSpec.describe PatientSpecificDirectionPolicy do
  subject(:policy) { described_class.new(user, PatientSpecificDirection) }

  context "cis2 is disabled", cis2: :disabled do
    describe "#create?" do
      context "when user is a nurse" do
        let(:user) { build(:user, :nurse) }

        it "permits creation" do
          expect(policy.create?).to be(true)
        end
      end

      context "when user is not a nurse" do
        let(:user) { build(:user, :healthcare_assistant) }

        it "denies creation" do
          expect(policy.create?).to be(false)
        end
      end
    end
  end
end
