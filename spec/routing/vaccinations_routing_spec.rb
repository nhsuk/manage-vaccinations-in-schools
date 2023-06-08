require "rails_helper"

RSpec.describe VaccinationsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/sessions/1/patients").to route_to(
        "vaccinations#index",
        session_id: "1"
      )
    end
  end
end
