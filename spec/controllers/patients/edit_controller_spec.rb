# frozen_string_literal: true

describe Patients::EditController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  context "GET edit_nhs_number" do
    subject { get :edit_nhs_number, params: { id: patient.id } }

    it_behaves_like "a controller that logs the patient ID"
  end

  context "PUT update_nhs_number" do
    subject do
      put :update_nhs_number,
          params: {
            id: patient.id,
            patient: {
              nhs_number: patient.nhs_number
            }
          }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
