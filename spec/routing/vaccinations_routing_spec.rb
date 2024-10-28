# frozen_string_literal: true

describe VaccinationsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/sessions/slug/vaccinations/actions").to route_to(
        "vaccinations#index",
        session_slug: "slug",
        section: "vaccinations",
        tab: "actions"
      )
    end
  end
end
