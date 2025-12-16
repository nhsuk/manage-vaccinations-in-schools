# frozen_string_literal: true

describe PatientsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  describe "PatientLoggingConcern" do
    context "show action" do
      subject { get :show, params: { id: patient.id } }

      it_behaves_like "a controller that logs the patient ID"
    end

    context "log action" do
      subject { get :log, params: { id: patient.id } }

      it_behaves_like "a controller that logs the patient ID"
    end

    context "edit action" do
      subject { get :edit, params: { id: patient.id } }

      it_behaves_like "a controller that logs the patient ID"
    end
  end
end
