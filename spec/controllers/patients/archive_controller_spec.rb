# frozen_string_literal: true

describe Patients::ArchiveController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  context "GET #new" do
    subject { get :new, params: { patient_id: patient.id } }

    it_behaves_like "a controller that logs the patient ID"
  end

  context "POST #create" do
    subject do
      post :create,
           params: {
             patient_id: patient.id,
             patient_archive_form: {
               nhs_number: patient.nhs_number,
               type: "other",
               other_details: "duplicate"
             }
           }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
