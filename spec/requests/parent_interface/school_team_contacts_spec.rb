# frozen_string_literal: true

describe "Parent interface school team contacts" do
  let(:team) { create(:team) }
  let!(:school) { create(:school, team:, name: "Test School") }

  describe "GET /find-team-contact/school (school step)" do
    context "without a search query" do
      before { get "/find-team-contact/school" }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the search form with search input" do
        expect(response.body).to include("Search for a school")
      end

      it "does not render school search results" do
        expect(response.body).not_to include("School search results")
      end
    end

    context "with a search query that matches no schools" do
      before { get "/find-team-contact/school", params: { q: "Nonexistent XYZ" } }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the search results section with no results message" do
        expect(response.body).to include(
          "No schools matching search criteria found"
        )
      end
    end

    context "with a search query that matches a school" do
      before { get "/find-team-contact/school", params: { q: "Test" } }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the matching school in the results" do
        expect(response.body).to include("Test School")
        expect(response.body).to include("value=\"#{school.id}\"")
      end

      it "includes a form to select the school and find contact details" do
        expect(response.body).to include("Find contact details")
      end
    end

    context "with school_id (form submission from results)" do
      before do
        put "/find-team-contact/school",
            params: {
              school_team_contact_form: { school_id: school.id },
              q: "Test"
            }
      end

      it "redirects to the contact details step" do
        expect(response).to redirect_to("/find-team-contact/contact-details")
      end
    end
  end

  describe "GET /find-team-contact/contact-details (contact_details step)" do
    context "when the school has team locations" do
      before do
        put "/find-team-contact/school",
            params: {
              school_team_contact_form: { school_id: school.id },
              q: "Test"
            }
        follow_redirect!
      end

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the school name and contact details section" do
        expect(response.body).to include("Test School")
        expect(response.body).to include("Contact details")
      end

      it "includes a link to search for another school" do
        expect(response.body).to include("Search for another school")
      end
    end

    context "when accessing without selecting a school first" do
      before { get "/find-team-contact/contact-details" }

      it "redirects to the school step" do
        expect(response).to redirect_to("/find-team-contact/school")
      end
    end
  end
end
