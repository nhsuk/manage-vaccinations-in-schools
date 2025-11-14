# frozen_string_literal: true

describe ParentRelationshipsController do
  let(:patient) { create(:patient) }
  let(:relationship) { create(:parent_relationship, patient:) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      get :edit,
                          params: {
                            patient_id: patient.id,
                            id: relationship.parent_id
                          }
                    end

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      patch :update,
                            params: {
                              patient_id: patient.id,
                              id: relationship.parent_id,
                              parent_relationship: {
                                type: relationship.type
                              }
                            }
                    end
  end
end
