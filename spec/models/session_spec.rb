# == Schema Information
#
# Table name: sessions
#
#  id          :bigint           not null, primary key
#  date        :datetime
#  draft       :boolean          default(FALSE)
#  name        :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  location_id :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id  (campaign_id)
#
require "rails_helper"

RSpec.describe Session do
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
