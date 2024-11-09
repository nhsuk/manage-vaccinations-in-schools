# frozen_string_literal: true

describe PatientPolicy do
  describe "Scope#resolve" do
    subject { PatientPolicy::Scope.new(user, Patient).resolve }

    let(:organisation) { create(:organisation) }
    let(:another_organisation) { create(:organisation) }
    let(:cohort) { create(:cohort, organisation:) }
    let(:cohort_for_another_organisation) do
      create(:cohort, organisation: another_organisation)
    end
    let(:school) { create(:location, :school, organisation:) }
    let(:user) { create(:user, organisations: [organisation]) }

    let(:patient_in_school) { create(:patient, school:) }
    let(:patient_in_cohort) { create(:patient, cohort:) }
    let(:patient_not_in_organisation) { create(:patient) }

    it { should include(patient_in_school) }
    it { should include(patient_in_cohort) }
    it { should_not include(patient_not_in_organisation) }

    context "when the patient not in the org but pending joining the cohort" do
      let(:patient_with_pending_changes_to_enrol_in_cohort) do
        create(:patient, pending_changes: { "cohort_id" => cohort.id })
      end

      let(:patient_with_pending_changes_to_enrol_in_another_cohort) do
        create(
          :patient,
          pending_changes: {
            "cohort_id" => cohort_for_another_organisation.id
          }
        )
      end

      it { should include(patient_with_pending_changes_to_enrol_in_cohort) }

      it do
        expect(subject).not_to include(
          patient_with_pending_changes_to_enrol_in_another_cohort
        )
      end
    end

    context "when the patient not in the org but pending joining the school" do
      let(:school_for_another_organisation) do
        create(:location, :school, organisation: another_organisation)
      end

      let(:patient_with_pending_changes_to_enrol_in_school) do
        create(:patient, pending_changes: { "school_id" => school.id })
      end

      let(:patient_with_pending_changes_to_enrol_in_another_school) do
        create(
          :patient,
          pending_changes: {
            "school_id" => school_for_another_organisation.id
          }
        )
      end

      it { should include(patient_with_pending_changes_to_enrol_in_school) }

      it do
        expect(subject).not_to include(
          patient_with_pending_changes_to_enrol_in_another_school
        )
      end
    end
  end
end
