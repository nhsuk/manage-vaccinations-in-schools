require "rails_helper"

describe PatientSessionPolicy do
  let(:patient_session1) { create :patient_session }
  let(:patient_session2) { create :patient_session }
  let(:team) { patient_session1.session.campaign.team }
  let(:user) { create :user, teams: [team] }

  describe "Scope#resolve" do
    subject { PatientSessionPolicy::Scope.new(user, PatientSession).resolve }

    it { should include patient_session1 }
    it { should_not include patient_session2 }
  end
end
