# frozen_string_literal: true

shared_examples "a controller that logs the patient ID" do
  before do
    allow(controller).to receive_messages(
      current_user: user,
      authenticate_user!: true,
      ensure_team_is_selected: true,
      set_user_cis2_info: true,
      verify_policy_scoped: true
    )
  end

  it "tags logs with patient_id" do
    tags = capture_log_tags { subject }
    expect(tags.select { it.is_a?(Hash) }).to include a_hash_including(
              patient_id: patient.id
            )
  end
end
