# frozen_string_literal: true

describe VaccinationRecordPolicy do
  subject(:policy) { described_class.new(user, vaccination_record) }

  describe "update?" do
    subject(:update?) { policy.update? }

    let(:programme) { create(:programme) }
    let(:team) { create(:team, programmes: [programme]) }

    let(:vaccination_record) { create(:vaccination_record, programme:) }

    context "with an admin" do
      let(:user) { create(:admin, teams: [team]) }

      it { should be(false) }

      context "when vaccination record is managed by the team" do
        let(:session) { create(:session, team:, programmes: [programme]) }
        let(:vaccination_record) do
          create(:vaccination_record, team:, programme:, session:)
        end

        it { should be(false) }
      end
    end

    context "with a nurse" do
      let(:user) { create(:nurse, teams: [team]) }

      it { should be(false) }

      context "when vaccination record is managed by the team" do
        let(:session) { create(:session, team:, programmes: [programme]) }
        let(:vaccination_record) do
          create(:vaccination_record, team:, programme:, session:)
        end

        it { should be(true) }
      end
    end
  end

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
    subject(:scope) do
      VaccinationRecordPolicy::Scope.new(user, VaccinationRecord).resolve
    end

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation) }

    let(:team) { create(:team, organisation:, programmes: [programme]) }
    let(:other_team) { create(:team, organisation:, programmes: [programme]) }
    let(:user) { create(:user, team:) }

    let(:session) { create(:session, team:, programmes: [programme]) }
    let(:other_session) do
      create(:session, team: other_team, programmes: [programme])
    end

    let(:kept_vaccination_record) do
      create(:vaccination_record, session:, programme:)
    end
    let(:discarded_vaccination_record) do
      create(:vaccination_record, :discarded, session:, programme:)
    end
    let(:non_team_kept_batch) { create(:vaccination_record, programme:) }
    let(:vaccination_record_same_organisation_different_team) do
      create(:vaccination_record, session: other_session, programme:)
    end

    it { should include(kept_vaccination_record) }
    it { should_not include(discarded_vaccination_record) }
    it { should_not include(non_team_kept_batch) }

    it do
      expect(scope).not_to include(
        vaccination_record_same_organisation_different_team
      )
    end
  end
end
