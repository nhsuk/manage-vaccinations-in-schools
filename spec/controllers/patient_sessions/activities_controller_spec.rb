# frozen_string_literal: true

describe PatientSessions::ActivitiesController do
  let(:session) { create(:session) }
  let(:patient) { create(:patient) }

  before do
    create(
      :patient_location,
      patient: patient,
      location: session.location,
      academic_year: session.academic_year
    )
  end

  describe "PatientLoggingConcern" do
    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      get :show,
                          params: {
                            session_slug: session.slug,
                            patient_id: patient.id
                          }
                    end

    it_behaves_like "a controller that logs the patient ID",
                    -> do
                      post :create,
                           params: {
                             session_slug: session.slug,
                             patient_id: patient.id,
                             note: {
                               body: "Hello"
                             }
                           }
                    end
  end
end
