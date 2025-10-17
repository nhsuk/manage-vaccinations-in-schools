# frozen_string_literal: true

describe ImportantNoticePolicy do
  let(:team) { create(:team) }
  let(:notice) { create(:important_notice, team_id: team.id) }
  let(:policy) { described_class.new(user, notice) }

  describe "Scope#resolve" do
    subject { ImportantNoticePolicy::Scope.new(user, ImportantNotice).resolve }

    let(:team) { create(:team) }
    let(:another_team) { create(:team) }
    let(:user) { create(:user, team:) }

    context "when notices are in different teams" do
      let(:notice_in_team) { create(:important_notice, team_id: team.id) }
      let(:notice_in_another_team) do
        create(:important_notice, team_id: another_team.id)
      end
      let(:notice_in_another_team_2) do
        create(:important_notice, team_id: another_team.id)
      end

      before do
        notice_in_team
        notice_in_another_team
        notice_in_another_team_2
      end

      it { should contain_exactly(notice_in_team) }
    end

    context "when multiple notices exist in the team" do
      let(:notice_one) { create(:important_notice, team_id: team.id) }
      let(:notice_two) { create(:important_notice, team_id: team.id) }
      let(:notice_in_another_team) do
        create(:important_notice, team_id: another_team.id)
      end

      before do
        notice_one
        notice_two
        notice_in_another_team
      end

      it { should contain_exactly(notice_one, notice_two) }
    end
  end

  shared_examples "local system admin access" do
    context "with a superuser" do
      let(:user) { create(:superuser, team:) }

      it { should be(true) }
    end

    context "with a nurse" do
      let(:user) { create(:nurse, team:) }

      it { should be(false) }
    end

    context "with a prescriber" do
      let(:user) { create(:prescriber, team:) }

      it { should be(false) }
    end

    context "with a healthcare assistant" do
      let(:user) { create(:healthcare_assistant, team:) }

      it { should be(false) }
    end

    context "with a medical secretary" do
      let(:user) { create(:medical_secretary, team:) }

      it { should be(false) }
    end
  end
end
