require "rails_helper"

RSpec.describe "/sessions/:session_id/triage", type: :request do
  let(:child) { create(:patient) }
  let(:session) { create(:session, patients: [child]) }

  describe "GET /sessions/:session_id/triage" do
    it "renders a successful response" do
      get session_triage_index_url(session)
      expect(response).to be_successful
    end

    it "lists children who are a part of this session" do
      get session_triage_index_url(session)
      expect(response.body).to include(session.patients.first.first_name)
    end

    describe "triage status" do
      it "shows child status" do
        get session_triage_index_url(session)
        expect(response.body).to include("To do")
      end
    end
  end
end
