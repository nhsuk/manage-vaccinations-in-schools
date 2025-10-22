# frozen_string_literal: true

shared_examples "a controller that logs the patient ID" do |action|
  let(:user) { create(:user, :support) }

  before do
    # Skip authentication for this test
    allow(controller).to receive_messages(
      authenticate_user!: true,
      ensure_team_is_selected: true,
      set_user_cis2_info: true,
      verify_policy_scoped: true,
      current_user: user
    )

    # Ensure the current user has access to all resources
    # so that patient id can be retrieved despite invalid authentication
    allow(PatientPolicy::Scope).to receive(:new).and_return(
      instance_double(PatientPolicy::Scope, resolve: Patient)
    )

    allow(ProgrammePolicy::Scope).to receive(:new).and_return(
      instance_double(ProgrammePolicy::Scope, resolve: Programme)
    )

    allow(SessionPolicy::Scope).to receive(:new).and_return(
      instance_double(SessionPolicy::Scope, resolve: Session)
    )

    allow(ConsentFormPolicy::Scope).to receive(:new).and_return(
      instance_double(ConsentFormPolicy::Scope, resolve: ConsentForm)
    )

    allow(VaccinationRecordPolicy::Scope).to receive(:new).and_return(
      instance_double(
        VaccinationRecordPolicy::Scope,
        resolve: VaccinationRecord
      )
    )
  end

  it "tags logs with patient_id" do
    tags = capture_log_tags { instance_exec(&action) }
    expect(tags).to include a_hash_including(patient_id: patient.id)
  end
end
