# frozen_string_literal: true

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

describe PatientSession do
  describe "#triage" do
    it "returns the triage records in ascending order" do
      patient_session = create(:patient_session)
      later_triage = create(:triage, patient_session:)
      earlier_triage = create(:triage, patient_session:, updated_at: 1.day.ago)

      expect(patient_session.triage).to eq [earlier_triage, later_triage]
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
    subject { patient_session.latest_consents }

    let(:campaign) { create(:campaign) }
    let(:patient_session) do
      create(:patient_session, patient:, session_attributes: { campaign: })
    end

    context "multiple consent given responses from different parents" do
      let(:consents) { build_list(:consent, 2, campaign:, response: :given) }
      let(:patient) { create(:patient, consents:) }

      it "groups consents by parent name" do
        expect(subject).to contain_exactly(consents.first, consents.second)
      end
    end

    context "multiple consent responses from same parents" do
      let(:parent) { create(:parent) }
      let(:refused_consent) do
        build :consent, campaign:, parent:, response: :refused
      end
      let(:given_consent) do
        build :consent, campaign:, parent:, response: :given
      end
      let(:patient) do
        create(:patient, consents: [refused_consent, given_consent])
      end

      it "returns the latest consent for each parent" do
        expect(subject).to eq [given_consent]
      end
    end

    context "multiple consent responses from same parent where one is draft" do
      let(:parent) { create(:parent) }
      let(:refused_recorded_consent) do
        build :consent,
              campaign:,
              parent:,
              recorded_at: 1.day.ago,
              response: :refused
      end
      let(:given_draft_consent) do
        build :consent, :draft, campaign:, parent:, response: :given
      end
      let(:patient) do
        create(
          :patient,
          consents: [refused_recorded_consent, given_draft_consent]
        )
      end

      it "does not return a draft consent record" do
        expect(subject).to eq [refused_recorded_consent]
      end
    end
  end

  describe "#latest_triage" do
    it "returns the latest triage record" do
      patient_session = create(:patient_session)
      create(
        :triage,
        status: :needs_follow_up,
        created_at: 1.day.ago,
        patient_session:
      )
      later_triage =
        create(:triage, status: :ready_to_vaccinate, patient_session:)

      expect(patient_session.latest_triage).to eq later_triage
    end
  end
end
