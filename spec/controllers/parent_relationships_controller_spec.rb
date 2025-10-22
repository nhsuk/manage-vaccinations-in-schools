# frozen_string_literal: true

describe ParentRelationshipsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, session:) }
  let(:relationship) { create(:parent_relationship, patient:) }

  describe "PatientLoggingConcern" do
    context "edit action" do
      subject do
        get :edit,
            params: {
              patient_id: patient.id,
              id: relationship.parent_id
            }
      end

      it_behaves_like "a controller that logs the patient ID"
    end

    context "update action" do
      subject do
        patch :update,
              params: {
                patient_id: patient.id,
                id: relationship.parent_id,
                parent_relationship: {
                  type: relationship.type
                }
              }
      end

      it_behaves_like "a controller that logs the patient ID"
    end
  end
end
