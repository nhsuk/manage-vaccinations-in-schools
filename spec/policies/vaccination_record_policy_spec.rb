# frozen_string_literal: true

describe VaccinationRecordPolicy do
  subject(:policy) { described_class.new(user, vaccination_record) }

  let(:programme) { CachedProgramme.sample }
  let(:team) { create(:team, programmes: [programme]) }

  describe "update?" do
    subject(:update?) { policy.update? }

    let(:vaccination_record) { create(:vaccination_record, programme:) }

    context "with a medical secretary" do
      let(:user) { create(:medical_secretary, teams: [team]) }

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

    context "with a prescriber" do
      let(:user) { create(:prescriber, teams: [team]) }

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

    context "when vaccination record is from the nhs immunisations api" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          programme:,
          source: "nhs_immunisations_api",
          nhs_immunisations_api_identifier_system: "ABC",
          nhs_immunisations_api_identifier_value: "123"
        )
      end

      context "with a medical secretary with superuser access" do
        let(:user) { build(:medical_secretary, :superuser) }

        it { should be(false) }
      end

      context "with a nurse with superuser access" do
        let(:user) { build(:nurse, :superuser) }

        it { should be(false) }
      end
    end

    context "when vaccination record is managed in mavis" do
      let(:session) { create(:session, team:, programmes: [programme]) }
      let(:vaccination_record) do
        create(
          :vaccination_record,
          team:,
          programme:,
          source: "service",
          session:
        )
      end

      context "with a medical secretary" do
        let(:user) { build(:medical_secretary) }

        it { should be(false) }

        context "and superuser access" do
          let(:user) { build(:medical_secretary, :superuser) }

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
  end

  describe "Scope#resolve" do
    subject(:scope) do
      VaccinationRecordPolicy::Scope.new(user, VaccinationRecord).resolve
    end

    let(:programme) { CachedProgramme.sample }
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
