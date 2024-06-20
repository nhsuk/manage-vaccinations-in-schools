require "rails_helper"

describe SessionPolicy do
  describe "Scope#resolve" do
    let(:team1) { create :team }
    let(:team2) { create :team }
    let(:user) { create :user, teams: [team1] }
    let(:campaign1) { create :campaign, team: team1 }
    let(:campaign2) { create :campaign, team: team2 }
    let(:session1) { create :session, campaign: campaign1 }
    let(:session2) { create :session, campaign: campaign2 }

    subject { SessionPolicy::Scope.new(user, Session).resolve }

    it { should include session1 }
    it { should_not include session2 }
  end

  describe "DraftScope#resolve" do
    let(:team) { create :team }
    let(:user) { create :user, teams: [team] }
    let(:location) { create :location, team: }
    let(:campaign) { create :campaign, team: }
    let(:draft_session) { create :session, draft: true, location:, campaign: }
    let(:session) { create :session, location:, campaign: }

    subject { SessionPolicy::DraftScope.new(user, Session).resolve }

    it { should include draft_session }
    it { should_not include session }

    context "location and campaign are nil" do
      let(:draft_session) do
        create :session, draft: true, location: nil, campaign: nil
      end

      it { should include draft_session }
    end

    context "location is set but not campaign" do
      let(:draft_session) do
        create :session, draft: true, location:, campaign: nil
      end
      let(:other_team) { create :team, name: "Other team" }
      let(:other_campaign) { create :campaign, team: other_team }
      let(:other_location) { create :location, team: other_team }
      let(:draft_session_other_location) do
        create :session, draft: true, location: other_location, campaign: nil
      end

      it { should include draft_session }
      it { should_not include draft_session_other_location }
    end

    context "campaign is set but not location" do
      let(:draft_session) do
        create :session, draft: true, location: nil, campaign:
      end

      it { should include draft_session }
    end
  end
end
