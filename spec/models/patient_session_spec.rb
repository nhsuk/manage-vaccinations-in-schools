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

  it { should have_many(:gillick_assessments) }
  it { should have_many(:pre_screenings) }

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

  describe "#next_activity" do
    subject { patient_session.next_activity(programme:) }

    let(:patient) { patient_session.patient }

    context "with no consent" do
      it { should be(:consent) }
    end

    context "with consent refused" do
      before { create(:patient_consent_status, :refused, patient:, programme:) }

      it { should be(:do_not_record) }
    end

    context "with triaged as do not vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :do_not_vaccinate, patient:, programme:)
      end

      it { should be(:do_not_record) }
    end

    context "with consent needing triage" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :required, patient:, programme:)
      end

      it { should be(:triage) }
    end

    context "with triaged as safe to vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :safe_to_vaccinate, patient:, programme:)
      end

      it { should be(:record) }
    end

    context "with consent no triage needed" do
      before { create(:patient_consent_status, :given, patient:, programme:) }

      it { should be(:record) }
    end

    context "with an administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_vaccination_status, :vaccinated, patient:, programme:)
      end

      it { should be_nil }
    end

    context "with an un-administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_vaccination_status, patient:, programme:)
      end

      it { should be(:record) }
    end
  end
end
