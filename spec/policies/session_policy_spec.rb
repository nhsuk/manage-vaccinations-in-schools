# frozen_string_literal: true

describe SessionPolicy do
  subject(:policy) { described_class.new(user, session) }

  shared_examples "edit/update session" do
    context "with an admin" do
      let(:user) { create(:admin) }

      context "with a scheduled session" do
        let(:session) { create(:session, :scheduled) }

        it { should be(true) }
      end

      context "with an unscheduled session" do
        let(:session) { create(:session, :unscheduled) }

        it { should be(true) }
      end
    end

    context "with a nurse" do
      let(:user) { create(:nurse) }

      context "with a scheduled session" do
        let(:session) { create(:session, :scheduled) }

        it { should be(true) }
      end

      context "with an unscheduled session" do
        let(:session) { create(:session, :unscheduled) }

        it { should be(true) }
      end
    end

    context "with a healthcare assistant" do
      let(:user) { create(:healthcare_assistant) }

      context "with a scheduled session" do
        let(:session) { create(:session, :scheduled) }

        it { should be(false) }
      end

      context "with an unscheduled session" do
        let(:session) { create(:session, :unscheduled) }

        it { should be(false) }
      end
    end
  end

  describe "#edit?" do
    subject(:edit?) { policy.edit? }

    include_examples "edit/update session"
  end

  describe "#update?" do
    subject(:update?) { policy.update? }

    include_examples "edit/update session"
  end

  describe SessionPolicy::Scope do
    describe "#resolve" do
      subject { described_class.new(user, Session).resolve }

      let(:user) { create(:user, team:) }

      let!(:flu_programme) { create(:programme, :flu) }
      let!(:hpv_programme) { create(:programme, :hpv) }

      let(:users_teams_session) { create(:session, team:, programmes:) }
      let(:another_teams_session) { create(:session, programmes:) }

      let(:programmes) { [hpv_programme] }
      let(:team) { create(:team, programmes:) }

      context "with a session part of the user's teams" do
        let(:session) { create(:session, team:, programmes:) }

        context "and an admin user" do
          let(:user) { create(:admin, team:) }

          it { should include(session) }
        end

        context "and a nurse user" do
          let(:user) { create(:nurse, team:) }

          it { should include(session) }
        end

        context "and a healthcare assistant user" do
          let(:user) { create(:healthcare_assistant, team:) }

          it { should_not include(session) }

          context "and a flu session" do
            let(:programmes) { [flu_programme] }

            it { should include(session) }
          end
        end
      end

      context "with a session not part of the user's teams" do
        let(:session) { create(:session, programmes:) }
        let(:user) { create(:user, team:) }

        it { should_not include(session) }
      end
    end
  end
end
