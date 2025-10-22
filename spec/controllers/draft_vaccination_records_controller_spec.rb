# frozen_string_literal: true

describe DraftVaccinationRecordsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }

  before do
    allow(controller).to receive(:session).and_return(
      { "vaccination_record" => { "patient_id" => patient.id } }
    )
  end

  context "show action" do
    subject { get :show, params: { id: "confirm" } }

    it_behaves_like "a controller that logs the patient ID"
  end

  context "update action" do
    subject do
      put :update,
          params: {
            id: "confirm",
            draft_vaccination_record: {
              wizard_step: :confirm,
              notes: "ok"
            }
          }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
