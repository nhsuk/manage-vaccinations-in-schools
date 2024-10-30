# frozen_string_literal: true

describe PatientPolicy do
  describe "Scope#resolve" do
    subject { PatientPolicy::Scope.new(user, Patient).resolve }

    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }

    let(:patient_in_school) do
      create(:patient, school: create(:location, :school, organisation:))
    end
    let(:patient_in_cohort) do
      create(:patient, cohort: create(:cohort, organisation:))
    end
    let(:patient_not_in_organisation) { create(:patient) }

    it { should include(patient_in_school) }
    it { should include(patient_in_cohort) }
    it { should_not include(patient_not_in_organisation) }
  end
end
