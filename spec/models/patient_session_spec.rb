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
#  index_patient_sessions_on_patient_id                 (patient_id)
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

  it { should have_many(:gillick_assessments).order(:created_at) }

  describe "#safe_to_destroy?" do
    subject(:safe_to_destroy?) { patient_session.safe_to_destroy? }

    let(:patient_session) { create(:patient_session, session:) }
    let(:patient) { patient_session.patient }

    context "when safe to destroy" do
      it { should be true }

      it "is safe with only absent attendances" do
        create(:session_attendance, :absent, patient_session:)
        expect(safe_to_destroy?).to be true
      end
    end

    context "when unsafe to destroy" do
      it "is unsafe with vaccination records" do
        create(:vaccination_record, programme:, patient:, session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with gillick assessment" do
        create(:gillick_assessment, :competent, patient_session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with present attendances" do
        create(:session_attendance, :present, patient_session:)
        expect(safe_to_destroy?).to be false
      end

      it "is unsafe with mixed conditions" do
        create(:session_attendance, :absent, patient_session:)
        create(:vaccination_record, programme:, patient:, session:)
        expect(safe_to_destroy?).to be false
      end
    end
  end

  describe "#ready_for_vaccinator?" do
    subject(:ready_for_vaccinator?) { patient_session.ready_for_vaccinator? }

    it { should be(false) }

    context "when attending the session" do
      let(:patient_session) do
        create(:patient_session, :in_attendance, session:)
      end

      it { should be(false) }
    end

    context "when attending the session and consent given and triaged as safe to vaccinate" do
      let(:patient_session) do
        create(
          :patient_session,
          :in_attendance,
          :consent_given_triage_not_needed,
          session:
        )
      end

      it { should be(true) }

      context "when already vaccinated" do
        let(:patient_session) do
          create(
            :patient_session,
            :in_attendance,
            :consent_given_triage_not_needed,
            :vaccinated,
            session:
          )
        end

        it { should be(false) }
      end
    end
  end
end
