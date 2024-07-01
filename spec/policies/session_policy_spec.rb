# frozen_string_literal: true

require "rails_helper"

describe SessionPolicy do
  describe "Scope#resolve" do
    subject { SessionPolicy::Scope.new(user, Session).resolve }

    let(:users_team) { create :team }
    let(:another_team) { create :team }
    let(:user) { create :user, teams: [users_team] }
    let(:users_teams_campaign) { create :campaign, team: users_team }
    let(:another_teams_campaign) { create :campaign, team: another_team }
    let(:users_teams_session) do
      create :session, campaign: users_teams_campaign
    end
    let(:another_teams_session) do
      create :session, campaign: another_teams_campaign
    end

    it { should include users_teams_session }
    it { should_not include another_teams_session }
  end

  describe "DraftScope#resolve" do
    subject { SessionPolicy::DraftScope.new(user, Session).resolve }

    let(:team) { create :team }
    let(:user) { create :user, teams: [team] }
    let(:location) { create :location, team: }
    let(:campaign) { create :campaign, team: }
    let(:draft_session) { create :session, draft: true, location:, campaign: }
    let(:session) { create :session, location:, campaign: }

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
