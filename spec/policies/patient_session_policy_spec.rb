# frozen_string_literal: true

describe PatientSessionPolicy do
  let(:programmes) { [create(:programme)] }

  let(:organisation) { create(:organisation, programmes:) }
  let(:user) { create(:user, organisation:) }

  let(:patient_session) do
    create(
      :patient_session,
      session: create(:session, organisation:, programmes:)
    )
  end
  let(:another_organisations_patient_session) do
    create(:patient_session, programmes:)
  end

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include(patient_session) }
    it { should_not include(another_organisations_patient_session) }
  end
end
