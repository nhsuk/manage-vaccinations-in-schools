# frozen_string_literal: true

describe Imports::IssuesController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:session) { create(:session, team:) }
  let(:patient) { create(:patient, :with_pending_changes, session:) }

  context "show action" do
    subject { get :show, params: { id: patient.id, type: "patient" } }

    it_behaves_like "a controller that logs the patient ID"
  end

  context "update action" do
    subject do
      patch :update,
            params: {
              id: patient.id,
              type: "patient",
              import_duplicate_form: {
                apply_changes: true
              }
            }
    end

    it_behaves_like "a controller that logs the patient ID"
  end
end
