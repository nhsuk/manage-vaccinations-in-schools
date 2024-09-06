# frozen_string_literal: true

describe PatientSessionPolicy do
  let(:patient_session) { create :patient_session }
  let(:another_teams_patient_session) do
    create :patient_session,
           session: create(:session, programme: create(:programme, :flu))
  end
  let(:team) { patient_session.session.programme.team }
  let(:user) { create :user, teams: [team] }

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include patient_session }
    it { should_not include another_teams_patient_session }
  end
end
