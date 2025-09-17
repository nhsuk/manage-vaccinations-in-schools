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

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }

  describe "associations" do
    it { should have_many(:attendance_records) }
    it { should have_many(:gillick_assessments) }
    it { should have_many(:pre_screenings) }
    it { should have_many(:vaccination_records) }
  end

  describe "scopes" do
    describe "#appear_in_programmes" do
      subject(:scope) do
        described_class.joins(:patient).appear_in_programmes(programmes)
      end

      let(:programmes) { create_list(:programme, 1, :td_ipv) }
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

    describe "#consent_given_and_ready_to_vaccinate" do
      subject(:scope) do
        described_class.consent_given_and_ready_to_vaccinate(
          programmes:,
          academic_year:,
          vaccine_method:
        )
      end

      let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }
      let(:session) { create(:session, programmes:) }
      let(:academic_year) { Date.current.academic_year }
      let(:vaccine_method) { nil }
      let(:patient_location) { patient.patient_locations.first }

      it { should be_empty }

      context "with a patient eligible for vaccination" do
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should include(patient_location) }
      end

      context "when filtering on nasal spray" do
        let(:vaccine_method) { "nasal" }

        context "with a patient eligible for vaccination" do
          let(:patient) do
            create(:patient, :consent_given_triage_not_needed, session:)
          end

          before do
            patient.consent_status(
              programme: programmes.first,
              academic_year:
            ).update!(vaccine_methods: %w[nasal injection])
          end

          it { should include(patient_location) }

          context "when the patient has been vaccinated for flu" do
            before do
              create(
                :vaccination_record,
                programme: programmes.first,
                session:,
                patient:
              )
              StatusUpdater.call(session:, patient:)
            end

            it { should_not include(patient_location) }
          end
        end
      end
    end
  end

  describe "#safe_to_destroy?" do
    subject(:safe_to_destroy?) { patient_location.safe_to_destroy? }

    let(:patient_location) { create(:patient_location, session:) }
    let(:patient) { patient_location.patient }

    context "when safe to destroy" do
      it { should be true }

      it "is safe with only absent attendances" do
        create(:attendance_record, :absent, patient:, session:)
        expect(safe_to_destroy?).to be true
      end
    end

    context "when unsafe to destroy" do
      it "is unsafe with vaccination records" do
        create(:vaccination_record, programme:, patient:, session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with gillick assessment" do
        create(:gillick_assessment, :competent, patient:, session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with present attendances" do
        create(:attendance_record, :present, patient:, session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with mixed conditions" do
        create(:attendance_record, :absent, patient:, session:)
        create(:vaccination_record, programme:, patient:, session:)
        expect(safe_to_destroy?).to be false
      end
    end
  end
end
