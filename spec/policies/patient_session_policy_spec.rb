# frozen_string_literal: true

describe PatientSessionPolicy do
  let(:programme) { create(:programme) }

  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) { create(:user, organisations: [organisation]) }

  let(:patient_session) do
    create(
      :patient_session,
      programme:,
      session: create(:session, organisation:, programme:)
    )
  end
  let(:another_organisations_patient_session) do
    create(:patient_session, programme:)
  end

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include(patient_session) }
    it { should_not include(another_organisations_patient_session) }
  end
end
