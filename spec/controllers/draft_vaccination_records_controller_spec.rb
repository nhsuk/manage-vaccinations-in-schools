# frozen_string_literal: true

describe DraftVaccinationRecordsController do
  let(:patient) { create(:patient) }

  describe "PatientLoggingConcern" do
    before do
      allow(controller).to receive(:session).and_return(
        { "vaccination_record" => { "patient_id" => patient.id } }
      )
    end

    it_behaves_like "a controller that logs the patient ID",
                    -> { get :show, params: { id: "confirm" } }

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      put :update,
                          params: {
                            id: "confirm",
                            draft_vaccination_record: {
                              wizard_step: :confirm,
                              notes: "ok"
                            }
                          }
                    end
  end
end
