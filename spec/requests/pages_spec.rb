require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to redirect_to("/start")
    end
  end

  describe "GET /sessions/:session_id/patients.json" do
    # Broken until we sort out vaccinations controller
    xit "has a no-store cache header" do
      campaign = create(:campaign)
      session = campaign.sessions.first
      get "/sessions/#{session.id}/patients.json"
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("0")
    end
  end
end
