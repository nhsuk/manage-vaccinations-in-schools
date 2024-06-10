# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  state              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  patient_id         :bigint           not null
#  session_id         :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_created_by_user_id         (created_by_user_id)
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
require "rails_helper"

RSpec.describe PatientSession do
  describe "#triage" do
    it "returns the triage records in ascending order" do
      later_triage = create(:triage)
      earlier_triage = create(:triage, updated_at: 1.day.ago)

      patient_sessions =
        create :patient_session, triage: [earlier_triage, later_triage]

      expect(patient_sessions.triage).to eq [earlier_triage, later_triage]
    end
  end

  describe "#vaccine_record" do
    it "returns the last non-draft vaccination record" do
      patient_session = create(:patient_session)
      vaccination_record = create(:vaccination_record, patient_session:)
      vaccination_record.update!(recorded_at: 1.day.ago)
      draft_vaccination_record = create(:vaccination_record, patient_session:)
      draft_vaccination_record.update!(recorded_at: nil)

      expect(patient_session.vaccination_record).to eq vaccination_record
    end
  end

  describe "#latest_consents" do
    let(:campaign) { create(:campaign) }
    let(:patient_session) { create(:patient_session, patient:, campaign:) }

    subject { patient_session.latest_consents }

    context "multiple consent given responses from different parents" do
      let(:consent_1) { build(:consent, campaign:, response: :given) }
      let(:consent_2) { build(:consent, campaign:, response: :given) }
      let(:patient) { create(:patient, consents: [consent_1, consent_2]) }

      it "groups consents by parent name" do
        is_expected.to include(consent_1, consent_2)
        expect(subject.size).to eq 2
      end
    end

    context "multiple consent responses from same parents" do
      let(:parent) { create(:parent) }
      let(:consent_1) { build :consent, campaign:, parent:, response: :refused }
      let(:consent_2) { build :consent, campaign:, parent:, response: :given }
      let(:patient) { create(:patient, consents: [consent_1, consent_2]) }

      it "returns the latest consent for each parent" do
        is_expected.to eq [consent_2]
      end
    end

    context "multiple consent responses from same parent where one is draft" do
      let(:parent) { create(:parent) }
      let(:consent_1) do
        build :consent,
              campaign:,
              parent:,
              recorded_at: 1.day.ago,
              response: :refused
      end
      let(:consent_2) do
        build :consent, campaign:, parent:, recorded_at: nil, response: :given
      end
      let(:patient) { create(:patient, consents: [consent_1, consent_2]) }

      it "does not return a draft consent record" do
        is_expected.to eq [consent_1]
      end
    end
  end

  describe "#latest_triage" do
    it "returns the latest triage record" do
      earlier_triage =
        build :triage, status: :needs_follow_up, created_at: 1.day.ago
      later_triage = build :triage, status: :ready_to_vaccinate

      patient_session =
        create :patient_session, triage: [earlier_triage, later_triage]

      expect(patient_session.latest_triage).to eq later_triage
    end
  end
end
