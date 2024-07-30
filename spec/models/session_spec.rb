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
#  imported_from_id  :bigint
#  location_id       :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id       (campaign_id)
#  index_sessions_on_imported_from_id  (imported_from_id)
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#
require "rails_helper"

describe Session do
  describe "validations" do
    context "when form_step is location" do
      subject { build(:session, form_step:, campaign:) }

      let(:form_step) { :location }
      let(:team) { create(:team) }
      let(:campaign) { create(:campaign, team:) }

      it { should validate_presence_of(:location_id).on(:update) }
    end
  end

  describe "#in_progress?" do
    subject { session.in_progress? }

    context "when the session is scheduled for today" do
      let(:session) { create(:session, :in_progress) }

      it { should be_truthy }
    end

    context "when the session is scheduled in the past" do
      let(:session) { create(:session, :in_past) }

      it { should be_falsey }
    end

    context "when the session is scheduled in the future" do
      let(:session) { create(:session, :in_future) }

      it { should be_falsey }
    end
  end

  describe ".active scope" do
    subject { described_class.active }

    let(:campaign) { create(:campaign) }
    let!(:active_session) { create(:session, campaign:) }
    let!(:draft_session) { create(:session, campaign:, draft: true) }

    it { should include active_session }
    it { should_not include draft_session }
  end
end
