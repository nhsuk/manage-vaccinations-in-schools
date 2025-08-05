# frozen_string_literal: true

describe PatientPolicy do
  describe "Scope#resolve" do
    subject { PatientPolicy::Scope.new(user, Patient).resolve }

    let(:programmes) { [create(:programme)] }
    let(:team) { create(:team, programmes:) }
    let(:another_team) { create(:team, programmes:) }
    let(:user) { create(:user, team:) }

    context "when a patient is archived" do
      let(:patient_archived_in_team) { create(:patient) }
      let(:patient_not_archived_in_team) { create(:patient) }

      before do
        create(
          :archive_reason,
          :imported_in_error,
          patient: patient_archived_in_team,
          team:
        )
        create(
          :archive_reason,
          :other,
          patient: patient_not_archived_in_team,
          team: another_team
        )
      end

      it { should contain_exactly(patient_archived_in_team) }
    end

    context "when a patient is in a session" do
      let(:patient_in_session) { create(:patient) }
      let(:patient_not_in_session) { create(:patient) }

      before do
        create(
          :patient_session,
          patient: patient_in_session,
          session: create(:session, team:, programmes:)
        )
        create(
          :patient_session,
          patient: patient_not_in_session,
          session: create(:session, team: another_team, programmes:)
        )
      end

      it { should contain_exactly(patient_in_session) }
    end

    context "when the patient not in the org but pending joining the cohort" do
      let(:patient_with_move_in_cohort) { create(:patient) }
      let(:patient_with_move_in_another_cohort) { create(:patient) }

      before do
        create(
          :school_move,
          :to_home_educated,
          patient: patient_with_move_in_cohort,
          team:
        )
        create(
          :school_move,
          :to_home_educated,
          patient: patient_with_move_in_another_cohort,
          team: another_team
        )
      end

      it { should contain_exactly(patient_with_move_in_cohort) }
    end

    context "when the patient not in the org but pending joining the school" do
      let(:patient_with_move_in_school) { create(:patient) }
      let!(:patient_with_move_in_another_school) { create(:patient) }

      let(:school) { create(:school, team:) }

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
          school: create(:school, team: another_team)
        )
      end

      it { should contain_exactly(patient_with_move_in_school) }
    end

    context "when the patient not in the org but was vaccinated by them" do
      let(:patient_with_vaccination_record) { create(:patient) }
      let(:patient_with_another_vaccination_record) { create(:patient) }

      before do
        create(
          :vaccination_record,
          patient: patient_with_vaccination_record,
          performed_ods_code: team.organisation.ods_code,
          programme: programmes.first
        )
        create(
          :vaccination_record,
          patient: patient_with_another_vaccination_record,
          performed_ods_code: nil,
          programme: programmes.first
        )
      end

      it { should contain_exactly(patient_with_vaccination_record) }
    end
  end
end
