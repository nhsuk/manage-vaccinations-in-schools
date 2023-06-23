require "rails_helper"

RSpec.describe "/sessions/:session_id/triage", type: :request do
  let(:patient) { create(:patient) }
  let(:session) { create(:session, patients: [patient]) }

  describe "GET /sessions/:session_id/triage" do
    before { get session_triage_index_url(session) }

    it "renders a successful response" do
      expect(response).to be_successful
    end

    it "lists children who are a part of this session" do
      expect(response.body).to include(session.patients.first.first_name)
    end

    describe "triage status" do
      it "shows child status" do
        expect(response.body).to include("No response")
      end
    end
  end

  describe "GET /sessions/:session_id/triage/:patient_id" do
    before { get session_triage_url(session, patient) }

    it "renders a successful response" do
      expect(response).to be_successful
    end

    it "shows the patient's name" do
      expect(response.body).to include(patient.first_name)
    end
  end
end
