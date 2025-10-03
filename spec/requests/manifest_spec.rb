# frozen_string_literal: true

describe "Manifest" do
  include ApplicationHelper

  context "without a digest string" do
    before { get "/manifest/application.json" }

    it "caches for an hour" do
      expect(response.headers["cache-control"]).to eq("max-age=3600, public")
    end
  end

  context "with a digest string" do
    before { get "/manifest/application-#{manifest_digest}.json" }

    it "caches forever" do
      expect(response.headers["cache-control"]).to eq(
        "max-age=3155695200, public, immutable"
      )
    end
  end
end
