# frozen_string_literal: true

describe PatientPolicy do
  describe "Scope#resolve" do
    subject { PatientPolicy::Scope.new(user, Patient).resolve }

    let(:organisation) { create(:organisation) }
    let(:another_organisation) { create(:organisation) }
    let(:school) { create(:school, organisation:) }
    let(:user) { create(:user, organisation:) }

    let(:patient_in_organisation) { create(:patient, organisation:) }
    let(:patient_not_in_organisation) { create(:patient) }

    it { should include(patient_in_organisation) }
    it { should_not include(patient_not_in_organisation) }

    context "when the patient not in the org but pending joining the cohort" do
      let(:patient_with_move_in_cohort) { create(:patient) }
      let(:patient_with_move_in_another_cohort) { create(:patient) }

      before do
        create(
          :school_move,
          :to_home_educated,
          patient: patient_with_move_in_cohort,
          organisation:
        )
        create(
          :school_move,
          :to_home_educated,
          patient: patient_with_move_in_another_cohort,
          organisation: another_organisation
        )
      end

      it { should include(patient_with_move_in_cohort) }
      it { should_not include(patient_with_move_in_another_cohort) }
    end

    context "when the patient not in the org but pending joining the school" do
      let(:patient_with_move_in_school) { create(:patient) }
      let(:patient_with_move_in_another_school) { create(:patient) }

      before do
        create(
          :school_move,
          :to_school,
          patient: patient_with_move_in_school,
          school:
        )
        create(
          :school_move,
          :to_school,
          patient: patient_with_move_in_another_school,
          school: create(:school, organisation: another_organisation)
        )
      end

      it { should include(patient_with_move_in_school) }
      it { should_not include(patient_with_move_in_another_school) }
    end

    context "when the patient not in the org but was vaccinated by them" do
      let(:patient_with_vaccination_record) { create(:patient) }
      let(:patient_with_another_vaccination_record) { create(:patient) }

      let(:programme) { create(:programme) }

      before do
        create(
          :vaccination_record,
          patient: patient_with_vaccination_record,
          performed_ods_code: organisation.ods_code,
          programme:
        )
        create(
          :vaccination_record,
          patient: patient_with_another_vaccination_record,
          programme:
        )
      end

      it { should include(patient_with_vaccination_record) }
      it { should_not include(patient_with_another_vaccination_record) }
    end
  end
end
