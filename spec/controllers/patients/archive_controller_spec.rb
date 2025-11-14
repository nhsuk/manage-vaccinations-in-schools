# frozen_string_literal: true

describe Patients::ArchiveController do
  let(:patient) { create(:patient) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> { get :new, params: { patient_id: patient.id } }

    it_behaves_like "a controller that logs the patient ID",
                    -> do
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
  end
end
