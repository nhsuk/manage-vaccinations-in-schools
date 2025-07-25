# frozen_string_literal: true

describe "/api/locations" do
  before { Flipper.enable(:api) }
  after { Flipper.disable(:api) }

  let(:team) { create(:team) }

  let!(:community_clinic) do
    create(:community_clinic, :open, name: "Location A", team:)
  end
  let!(:generic_clinic) do
    create(:generic_clinic, :closed, name: "Location B", team:)
  end
  let!(:gp_practice) do
    create(:gp_practice, :closed, name: "Location C", team:)
  end
  let!(:primary_school) do
    create(:school, :primary, :closed, name: "Location D", team: nil)
  end
  let!(:secondary_school) do
    create(:school, :secondary, :closed, name: "Location E", team: nil)
  end

  describe "GET" do
    it "includes all locations" do
      get "/api/locations"

      expect(response).to have_http_status(:ok)

      locations = JSON.parse(response.body)

      expect(locations).to eq(
        [
          community_clinic,
          generic_clinic,
          gp_practice,
          primary_school,
          secondary_school
        ].map(&:as_json)
      )
    end

    context "when filtering by status" do
      it "includes only relevant locations" do
        get "/api/locations", params: { status: "open" }

        expect(response).to have_http_status(:ok)

        locations = JSON.parse(response.body)

        expect(locations).to eq([community_clinic.as_json])
      end
    end

    context "when filtering by type" do
      it "includes only relevant locations" do
        get "/api/locations", params: { type: "gp_practice" }

        expect(response).to have_http_status(:ok)

        locations = JSON.parse(response.body)

        expect(locations).to eq([gp_practice.as_json])
      end
    end

    context "when filtering by year groups" do
      it "includes only relevant locations" do
        get "/api/locations", params: { year_groups: [1] }

        expect(response).to have_http_status(:ok)

        locations = JSON.parse(response.body)

        expect(locations).to contain_exactly(
          primary_school.as_json,
          generic_clinic.as_json
        )
      end

      context "with multiple year groups" do
        before { create(:school, year_groups: [8, 9]) }

        let!(:secondary_school) { create(:school, year_groups: [8, 9, 10]) }

        it "includes locations with all those year groups" do
          get "/api/locations", params: { year_groups: [8, 9, 10] }

          expect(response).to have_http_status(:ok)

          locations = JSON.parse(response.body)

          expect(locations).to contain_exactly(
            secondary_school.as_json,
            generic_clinic.as_json
          )
        end
      end
    end

    context "when filtering by attached to organisation" do
      it "includes only relevant locations" do
        get "/api/locations", params: { is_attached_to_organisation: "false" }

        expect(response).to have_http_status(:ok)

        locations = JSON.parse(response.body)

        expect(locations).to eq(
          [primary_school, secondary_school].map(&:as_json)
        )
      end
    end
  end
end
