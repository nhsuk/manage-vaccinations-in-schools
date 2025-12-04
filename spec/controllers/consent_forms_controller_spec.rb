# frozen_string_literal: true

describe ConsentFormsController do
  let(:programme) { Programme.sample }
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:consent_form) { create(:consent_form, :recorded, session:) }
  let(:patient) { create(:patient, session:) }

  describe "GET #edit_match" do
    subject do
      get :edit_match, params: { id: consent_form.id, patient_id: patient.id }
    end

    it_behaves_like "a controller that logs the patient ID"
  end

  describe "POST #update_match" do
    subject do
      post :update_match,
           params: {
             id: consent_form.id,
             patient_id: patient.id
           }
    end

    it_behaves_like "a method that updates team cached counts"
    it_behaves_like "a controller that logs the patient ID"
  end

  describe "POST #create_patient" do
    subject { post :create_patient, params: { id: consent_form.id } }

    it_behaves_like "a method that updates team cached counts"
  end
end
