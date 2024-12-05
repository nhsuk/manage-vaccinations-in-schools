# frozen_string_literal: true

describe VaccinationRecordPolicy do
  subject(:policy) { described_class.new(user, vaccination_record) }

  describe "destroy?" do
    subject(:destroy?) { policy.destroy? }

    let(:vaccination_record) { create(:vaccination_record) }

    context "with an admin" do
      let(:user) { build(:admin) }

      it { should be(false) }

      context "and superuser access" do
        let(:user) { build(:admin, :superuser) }

        it { should be(true) }
      end
    end

    context "with a nurse" do
      let(:user) { build(:nurse) }

      it { should be(false) }

      context "and superuser access" do
        let(:user) { build(:nurse, :superuser) }

        it { should be(true) }
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
