# frozen_string_literal: true

RSpec.describe CampaignsHelper, type: :helper do
  describe "#campaign_academic_year" do
    subject(:campaign_academic_year) { helper.campaign_academic_year(campaign) }

    let(:campaign) { create(:campaign, academic_year: 2024) }

    it { should eq("2024/25") }
  end
end
