require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to redirect_to("/start")
    end
  end

  describe "GET /campaigns/:campaign_id/children.json" do
    it "has a no-store cache header" do
      campaign = create(:campaign)
      get "/campaigns/#{campaign.id}/children.json"
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("0")
    end
  end
end
