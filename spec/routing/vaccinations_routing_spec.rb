# frozen_string_literal: true

require "rails_helper"

describe VaccinationsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/sessions/1/vaccinations/actions").to route_to(
        "vaccinations#index",
        session_id: "1",
        section: "vaccinations",
        tab: "actions"
      )
    end
  end
end
