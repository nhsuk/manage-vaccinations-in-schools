# frozen_string_literal: true

describe PatientSessionPolicy do
  let(:team) { create(:team) }
  let(:user) { create(:user, teams: [team]) }

  let(:programme) { create(:programme, team:) }
  let(:patient_session) do
    create(
      :patient_session,
      programme:,
      session: create(:session, team:, programme:)
    )
  end
  let(:another_teams_patient_session) { create(:patient_session) }

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include(patient_session) }
    it { should_not include(another_teams_patient_session) }
  end
end
