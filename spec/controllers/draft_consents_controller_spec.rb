# frozen_string_literal: true

describe DraftConsentsController do
  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  describe "PatientLoggingConcern" do
    before do
      allow(controller).to receive_messages(
        session: {
          "consent" => {
            "patient_id" => patient.id,
            "programme_id" => programme.id
          }
        }
      )

      # Avoid hitting complex persistence paths irrelevant to logging in update action
      allow(controller).to receive(:handle_confirm).and_return(nil)
    end

    it_behaves_like "a controller that logs the patient ID",
                    -> { get :show, params: { id: "confirm" } }

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      put :update,
                          params: {
                            id: "confirm",
                            draft_consent: {
                              wizard_step: :confirm,
                              notes: "ok"
                            }
                          }
                    end
  end
end
