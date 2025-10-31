# frozen_string_literal: true

describe VaccinationRecordsController do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:vaccination_record) { create(:vaccination_record, team:) }
  let(:patient) { vaccination_record.patient }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> { get :show, params: { id: vaccination_record.id } }

    it_behaves_like "a controller that logs the patient ID",
                    -> { put :update, params: { id: vaccination_record.id } }
  end
end
