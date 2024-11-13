# frozen_string_literal: true

describe VaccinationRecordPolicy do
  subject(:policy) { described_class.new(user, vaccination_record) }

  describe "destroy?" do
    subject(:destroy?) { policy.destroy? }

    let(:programme) { create(:programme) }
    let(:vaccination_record) do
      create(:vaccination_record, session:, programme:)
    end

    context "when session is open" do
      let(:session) { create(:session, :scheduled, programme:) }

      context "with an admin" do
        let(:user) { create(:admin) }

        it { should be(false) }
      end

      context "with a nurse" do
        let(:user) { create(:nurse) }

        it { should be(true) }
      end
    end

    context "when session is not open" do
      let(:session) { create(:session, :closed, programme:) }

      context "with an admin" do
        let(:user) { create(:admin) }

        it { should be(false) }
      end

      context "with a nurse" do
        let(:user) { create(:nurse) }

        it { should be(false) }
      end
    end
  end
end
