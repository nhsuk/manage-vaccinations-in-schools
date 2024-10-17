# frozen_string_literal: true

describe PatientPolicy do
  describe "Scope#resolve" do
    subject { PatientPolicy::Scope.new(user, Patient).resolve }

    let(:team) { create(:team) }
    let(:user) { create(:user, teams: [team]) }

    let(:patient_in_school) do
      create(:patient, school: create(:location, :school, team:))
    end
    let(:patient_in_cohort) { create(:patient, cohort: create(:cohort, team:)) }
    let(:patient_not_in_team) { create(:patient) }

    it { should include(patient_in_school) }
    it { should include(patient_in_cohort) }
    it { should_not include(patient_not_in_team) }
  end
end
