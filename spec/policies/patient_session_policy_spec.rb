# frozen_string_literal: true

describe PatientSessionPolicy do
  let(:programmes) { [create(:programme)] }

  let(:team) { create(:team, programmes:) }
  let(:user) { create(:user, team:) }

  let(:patient_session) do
    create(:patient_session, session: create(:session, team:, programmes:))
  end
  let(:another_teams_patient_session) { create(:patient_session, programmes:) }

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include(patient_session) }
    it { should_not include(another_teams_patient_session) }
  end
end
