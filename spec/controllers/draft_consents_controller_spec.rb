# frozen_string_literal: true

describe DraftConsentsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }
  let(:programme) { Programme.sample }

  before do
    allow(controller).to receive_messages(
      session: {
        "consent" => {
          "patient_id" => patient.id,
          "programme_type" => programme.type
        }
      }
    )

    # Avoid hitting complex persistence paths irrelevant to logging in update action
    allow(controller).to receive(:handle_confirm).and_return(nil)
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
            draft_consent: {
              wizard_step: :confirm,
              notes: "ok"
            }
          }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
