# frozen_string_literal: true

describe PatientsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> { get :show, params: { id: patient.id } }

    it_behaves_like "a controller that logs the patient ID",
                    -> { get :log, params: { id: patient.id } }

    it_behaves_like "a controller that logs the patient ID",
                    -> { get :edit, params: { id: patient.id } }
  end
end
