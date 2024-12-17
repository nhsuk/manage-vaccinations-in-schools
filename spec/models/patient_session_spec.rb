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
  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programme:) }

  describe "#vaccination_records" do
    subject(:vaccination_records) { patient_session.vaccination_records }

    let(:kept_vaccination_record) do
      create(:vaccination_record, patient_session:, programme:)
    end
    let(:discarded_vaccination_record) do
      create(:vaccination_record, :discarded, patient_session:, programme:)
    end

    it { should include(kept_vaccination_record) }
    it { should_not include(discarded_vaccination_record) }
  end

  describe "#triages" do
    subject(:triages) { patient_session.triages }

    let(:patient) { patient_session.patient }
    let(:later_triage) { create(:triage, programme:, patient:) }
    let(:earlier_triage) do
      create(:triage, programme:, patient:, updated_at: 1.day.ago)
    end

    it { should eq([earlier_triage, later_triage]) }
  end

  describe "#latest_triage" do
    subject(:latest_triage) { patient_session.latest_triage }

    let(:patient) { patient_session.patient }
    let(:later_triage) do
      create(
        :triage,
        created_at: 1.day.ago,
        programme:,
        status: :ready_to_vaccinate,
        patient:
      )
    end

    before do
      create(
        :triage,
        programme:,
        status: :needs_follow_up,
        created_at: 2.days.ago,
        patient:
      )

      # should not be returned as invalidated even if more recent
      create(
        :triage,
        :invalidated,
        programme:,
        status: :ready_to_vaccinate,
        patient:
      )
    end

    it { should eq(later_triage) }
  end

  describe "#no_consent?" do
    subject(:no_consent?) { patient_session.no_consent? }

    let(:patient) { patient_session.patient }

    context "with no consent" do
      it { should be(true) }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be(true) }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be(true) }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be(true) }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(false) }
    end

    context "with a given consent" do
      before { create(:consent, :given, patient:, programme:) }

      it { should be(false) }
    end
  end

  describe "#latest_consents" do
    subject(:latest_consents) { patient_session.latest_consents }

    let(:patient_session) { create(:patient_session, programme:, patient:) }

    before { patient_session.strict_loading!(false) }

    context "multiple consent given responses from different parents" do
      let(:parents) { create_list(:parent, 2) }
      let(:consents) do
        [
          build(:consent, :given, parent: parents.first, programme:),
          build(:consent, :given, parent: parents.second, programme:)
        ]
      end
      let(:patient) { create(:patient, parents:, consents:) }

      it "groups consents by parent name" do
        expect(latest_consents).to contain_exactly(
          consents.first,
          consents.second
        )
      end
    end

    context "multiple consent responses from same parents" do
      let(:parent) { create(:parent) }
      let(:refused_consent) { build(:consent, :refused, programme:, parent:) }
      let(:given_consent) { build(:consent, :given, programme:, parent:) }
      let(:patient) do
        create(
          :patient,
          parents: [parent],
          consents: [refused_consent, given_consent]
        )
      end

      it "returns the latest consent for each parent" do
        expect(latest_consents).to eq [given_consent]
      end
    end

    context "with an invalidated consent" do
      let(:parent) { create(:parent) }
      let(:invalidated_consent) do
        build(:consent, :given, :invalidated, programme:, parent:)
      end
      let(:patient) do
        create(:patient, parents: [parent], consents: [invalidated_consent])
      end

      it "does not return the consent record" do
        expect(latest_consents).not_to include(invalidated_consent)
      end
    end
  end

  describe "#latest_gillick_assessment" do
    subject(:latest_gillick_assessment) do
      patient_session.latest_gillick_assessment
    end

    let(:later_gillick_assessment) do
      create(:gillick_assessment, :competent, patient_session:)
    end

    before do
      create(
        :gillick_assessment,
        :not_competent,
        patient_session:,
        created_at: 1.day.ago
      )
    end

    it { should eq(later_gillick_assessment) }
  end

  describe "#latest_vaccination_record" do
    subject(:latest_vaccination_record) do
      patient_session.latest_vaccination_record
    end

    let(:patient_session) { create(:patient_session, programme:) }
    let(:later_vaccination_record) do
      create(:vaccination_record, programme:, patient_session:)
    end

    before do
      create(
        :vaccination_record,
        programme:,
        patient_session:,
        created_at: 1.day.ago
      )
    end

    it { should eq(later_vaccination_record) }
  end

  describe "#safe_to_destroy?" do
    subject(:safe_to_destroy?) { patient_session.safe_to_destroy? }

    let(:patient_session) { create(:patient_session, programme:) }

    context "when safe to destroy" do
      it { should be true }

      it "is safe with only absent attendances" do
        create(:session_attendance, :absent, patient_session:)
        expect(safe_to_destroy?).to be true
      end
    end

    context "when unsafe to destroy" do
      it "is unsafe with vaccination records" do
        create(:vaccination_record, programme:, patient_session:)
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
        create(:vaccination_record, programme:, patient_session:)
        expect(safe_to_destroy?).to be false
      end
    end
  end
end
