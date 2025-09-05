# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id                 (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#

describe PatientSession do
  subject(:patient_session) { create(:patient_session, session:) }

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }

  describe "associations" do
    it { should have_many(:gillick_assessments) }
    it { should have_many(:pre_screenings) }
  end

  describe "scopes" do
    describe "#appear_in_programmes" do
      subject(:scope) do
        described_class.joins(:patient, :session).appear_in_programmes(
          programmes
        )
      end

      let(:programmes) { create_list(:programme, 1, :td_ipv) }
      let(:session) { create(:session, programmes:) }

      it { should be_empty }

      context "in a session with the right year group" do
        let(:patient_session) do
          create(:patient_session, session:, year_group: 9)
        end

        it { should include(patient_session) }
      end

      context "in a session but the wrong year group" do
        let(:patient_session) do
          create(:patient_session, session:, year_group: 8)
        end

        it { should_not include(patient_session) }
      end

      context "in a session with the right year group for the programme but not the location" do
        let(:location) { create(:school, :secondary) }
        let(:session) { create(:session, location:, programmes:) }

        let(:patient_session) { create(:patient, session:, year_group: 9) }

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

        it { should_not include(patient_session) }
      end
    end

    describe "#consent_given_and_ready_to_vaccinate" do
      subject(:scope) do
        described_class.consent_given_and_ready_to_vaccinate(
          programmes:,
          vaccine_method:
        )
      end

      let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }
      let(:academic_year) { Date.current.academic_year }
      let(:vaccine_method) { nil }

      it { should be_empty }

      context "with a patient eligible for vaccination" do
        let(:patient_session) do
          create(
            :patient_session,
            :consent_given_triage_not_needed,
            programmes:
          )
        end

        it { should include(patient_session) }
      end

      context "when filtering on nasal spray" do
        let(:vaccine_method) { "nasal" }

        context "with a patient eligible for vaccination" do
          let(:patient_session) do
            create(
              :patient_session,
              :consent_given_triage_not_needed,
              programmes:
            )
          end

          before do
            patient_session
              .patient
              .consent_status(programme: programmes.first, academic_year:)
              .update!(vaccine_methods: %w[nasal injection])
          end

          it { should include(patient_session) }

          context "when the patient has been vaccinated for flu" do
            before do
              create(
                :vaccination_record,
                programme: programmes.first,
                session: patient_session.session,
                patient: patient_session.patient
              )
              StatusUpdater.call(
                session: patient_session.session,
                patient: patient_session.patient
              )
            end

            it { should_not include(patient_session) }
          end
        end
      end
    end
  end

  describe "#safe_to_destroy?" do
    subject(:safe_to_destroy?) { patient_session.safe_to_destroy? }

    let(:patient_session) { create(:patient_session, session:) }
    let(:patient) { patient_session.patient }

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
