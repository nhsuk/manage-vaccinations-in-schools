# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_locations
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  location_id   :bigint           not null
#  patient_id    :bigint           not null
#
# Indexes
#
#  idx_on_location_id_academic_year_patient_id_3237b32fa0    (location_id,academic_year,patient_id) UNIQUE
#  idx_on_patient_id_location_id_academic_year_08a1dc4afe    (patient_id,location_id,academic_year) UNIQUE
#  index_patient_locations_on_location_id                    (location_id)
#  index_patient_locations_on_location_id_and_academic_year  (location_id,academic_year)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#

describe PatientLocation do
  subject(:patient_location) { create(:patient_location, session:) }

  let(:programme) { Programme.sample }
  let(:session) { create(:session, programmes: [programme]) }

  describe "associations" do
    it { should have_many(:attendance_records) }
    it { should have_many(:gillick_assessments) }
    it { should have_many(:pre_screenings) }
    it { should have_many(:vaccination_records) }
  end

  describe "callbacks" do
    it "creates a patient team" do
      expect { patient_location }.to change(PatientTeam, :count).by(1)

      patient_team = PatientTeam.last
      expect(patient_team.patient_id).to eq(patient_location.patient_id)
      expect(patient_team.team_id).to eq(session.team_id)
      expect(patient_team.sources).to eq(%w[patient_location])
    end

    it "deletes a patient team" do
      patient_location

      expect { patient_location.destroy! }.to change(PatientTeam, :count).by(-1)
    end

    it "creates patient teams in bulk" do
      patient_location.update!(academic_year: 2000) # no sessions exist for this academic year

      expect(PatientTeam.count).to eq(0)

      expect {
        described_class.where(
          id: patient_location.id
        ).update_all_and_sync_patient_teams(
          academic_year: session.academic_year
        )
      }.to change(PatientTeam, :count).by(1)

      patient_team = PatientTeam.last
      expect(patient_team.patient_id).to eq(patient_location.patient_id)
      expect(patient_team.team_id).to eq(session.team_id)
      expect(patient_team.sources).to eq(%w[patient_location])
    end

    context "when a patient has two patient locations that contribute" do
      let(:patient) { create(:patient) }
      let(:team) { create(:team) }
      let(:session_a) { create(:session, team:) }
      let(:session_b) { create(:session, team:) }
      let!(:patient_location_a) do
        create(:patient_location, patient:, session: session_a)
      end
      let!(:patient_location_b) do
        create(:patient_location, patient:, session: session_b)
      end

      it "keeps the patient team relationship when one is destroyed" do
        expect(patient.reload.teams).to contain_exactly(team)

        patient_location_a.destroy!
        expect(patient_location_b).not_to be_nil

        expect(patient.reload.teams).to contain_exactly(team)
      end

      it "keeps the patient team relationship when one is updated" do
        expect(patient.reload.teams).to contain_exactly(team)

        patient_location_a.update!(location: create(:school))
        expect(patient_location_b).not_to be_nil

        expect(patient.reload.teams).to contain_exactly(team)
      end
    end
  end

  describe "scopes" do
    describe "#appear_in_programmes" do
      subject(:scope) do
        described_class
          .joins_sessions
          .joins(:patient)
          .appear_in_programmes(programmes)
      end

      let(:programmes) { [Programme.td_ipv] }
      let(:session) { create(:session, programmes:) }

      let(:patient_location) { create(:patient_location, patient:, session:) }

      it { should be_empty }

      context "in a session with the right year group" do
        let(:patient) { create(:patient, year_group: 9) }

        it { should include(patient_location) }
      end

      context "in a session but the wrong year group" do
        let(:patient) { create(:patient, year_group: 8) }

        it { should_not include(patient_location) }
      end

      context "in a session with the right year group for the programme but not the location" do
        let(:location) { create(:school, :secondary) }
        let(:session) { create(:session, location:, programmes:) }
        let(:patient) { create(:patient, year_group: 9) }

        before do
          programmes.each do |programme|
            create(
              :location_programme_year_group,
              programme:,
              location:,
              year_group: 10
            )
          end
        end

        it { should_not include(patient_location) }
      end
    end
  end

  describe "#update_all_and_sync_patient_teams" do
    context "when a patient has two patient locations that contribute" do
      let(:patient) { create(:patient) }
      let(:team) { create(:team) }
      let(:session_a) { create(:session, team:) }
      let(:session_b) { create(:session, team:) }
      let!(:patient_location_a) do
        create(:patient_location, patient:, session: session_a)
      end
      let!(:patient_location_b) do
        create(:patient_location, patient:, session: session_b)
      end

      it "keeps the patient team relationship when one is updated" do
        expect(patient.reload.teams).to contain_exactly(team)

        described_class.where(
          id: patient_location_a
        ).update_all_and_sync_patient_teams(location_id: create(:school).id)
        expect(patient_location_b).not_to be_nil

        expect(patient.reload.teams).to contain_exactly(team)
      end
    end
  end

  describe "#safe_to_destroy?" do
    subject { patient_location.safe_to_destroy? }

    let(:patient_location) { create(:patient_location, session:) }
    let(:patient) { patient_location.patient }
    let(:location) { patient_location.location }

    it { should be(true) }

    context "with only absent attendance records" do
      before { create(:attendance_record, :absent, patient:, session:) }

      it { should be(true) }
    end

    context "with a vaccination record" do
      before { create(:vaccination_record, programme:, patient:, session:) }

      it { should be(false) }
    end

    context "with a Gillick assessment" do
      before { create(:gillick_assessment, :competent, patient:, session:) }

      it { should be(false) }
    end

    context "with an attendance record" do
      before { create(:attendance_record, :present, patient:, session:) }

      it { should be(false) }
    end

    context "with an attendance record from a different academic year" do
      before do
        create(
          :attendance_record,
          :present,
          patient:,
          location:,
          date: 1.year.ago
        )
      end

      it { should be(true) }
    end

    context "with a mix of conditions" do
      before do
        create(:attendance_record, :absent, patient:, session:)
        create(:vaccination_record, programme:, patient:, session:)
      end

      it { should be(false) }
    end
  end
end
