require "rails_helper"

RSpec.describe "CSRF Controller", type: :request do
  describe "GET /new" do
    it "returns a csrf token" do
      get "/csrf"

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/token/)
    end
  end
end
