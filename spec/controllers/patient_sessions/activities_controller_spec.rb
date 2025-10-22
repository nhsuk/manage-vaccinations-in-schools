# frozen_string_literal: true

describe PatientSessions::ActivitiesController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  context "GET #show" do
    subject do
      get :show, params: { session_slug: session.slug, patient_id: patient.id }
    end

    it_behaves_like "a controller that logs the patient ID"
  end

  context "POST #create" do
    subject do
      post :create,
           params: {
             session_slug: session.slug,
             patient_id: patient.id,
             note: {
               body: "Hello"
             }
           }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
