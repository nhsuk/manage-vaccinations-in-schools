# frozen_string_literal: true

describe ConsentFormsController do
  let(:consent_form) { create(:consent_form, :recorded) }
  let(:patient) { create(:patient) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      get :edit_match,
                          params: {
                            id: consent_form.id,
                            patient_id: patient.id
                          }
                    end

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      post :update_match,
                           params: {
                             id: consent_form.id,
                             patient_id: patient.id
                           }
                    end
  end
end
