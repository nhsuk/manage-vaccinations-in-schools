# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                :bigint           not null, primary key
#  close_consent_at  :date
#  date              :date
#  draft             :boolean          default(FALSE)
#  send_consent_at   :date
#  send_reminders_at :date
#  time_of_day       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :bigint
#  location_id       :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id  (campaign_id)
#
require "rails_helper"

describe Session do
  describe "validations" do
    context "when form_step is location" do
      let(:form_step) { :location }
      let(:location) { create :location }
      let(:team) { create :team, locations: [location] }
      let(:campaign) { create :campaign, team: }

      subject { FactoryBot.build :session, form_step:, campaign: }

      it { should validate_presence_of(:location_id).on(:update) }

      it "validates location_id is one of the team's locations" do
        expect(subject).to(
          validate_inclusion_of(:location_id).in_array(
            subject.campaign.team.locations.pluck(:id)
          ).on(:update)
        )
      end
    end
  end

  describe "#in_progress?" do
    subject { session.in_progress? }

    context "when the session is scheduled for today" do
      let(:session) { FactoryBot.create :session, :in_progress }

      it { should be_truthy }
    end

    context "when the session is scheduled in the past" do
      let(:session) { FactoryBot.create :session, :in_past }

      it { should be_falsey }
    end

    context "when the session is scheduled in the future" do
      let(:session) { FactoryBot.create :session, :in_future }

      it { should be_falsey }
    end
  end

  describe ".active scope" do
    subject { Session.active }

    let!(:active_session) { FactoryBot.create :session }
    let!(:draft_session) { FactoryBot.create :session, draft: true }

    it { should include active_session }
    it { should_not include draft_session }
  end
end
