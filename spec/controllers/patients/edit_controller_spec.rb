# frozen_string_literal: true

describe Patients::EditController do
  let(:patient) { create(:patient) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> { get :edit_nhs_number, params: { id: patient.id } }
    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      put :update_nhs_number,
                          params: {
                            id: patient.id,
                            patient: {
                              nhs_number: patient.nhs_number
                            }
                          }
                    end
  end
end
