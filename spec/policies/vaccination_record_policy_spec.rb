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

  describe "Scope#resolve" do
    subject(:resolve) do
      VaccinationRecordPolicy::Scope.new(user, VaccinationRecord).resolve
    end

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:user) { create(:user, organisation:) }

    let(:session) { create(:session, organisation:, programme:) }

    let(:kept_vaccination_record) do
      create(:vaccination_record, session:, programme:)
    end
    let(:discarded_vaccination_record) do
      create(:vaccination_record, :discarded, session:, programme:)
    end
    let(:non_organisation_kept_batch) do
      create(:vaccination_record, programme:)
    end

    it { should include(kept_vaccination_record) }
    it { should_not include(discarded_vaccination_record) }
    it { should_not include(non_organisation_kept_batch) }
  end
end
