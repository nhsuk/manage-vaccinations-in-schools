# frozen_string_literal: true

describe Imports::IssuesController do
  let(:patient) { create(:patient) }

  describe "PatientLoggingConcern" do
    before do
      # Ensure the patient appears in import issues
      patient.update!(pending_changes: { foo: "bar" })
    end

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      get :show, params: { id: patient.id, type: "patient" }
                    end

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      patch :update,
                            params: {
                              id: patient.id,
                              type: "patient",
                              import_duplicate_form: {
                                apply_changes: true
                              }
                            }
                    end
  end
end
