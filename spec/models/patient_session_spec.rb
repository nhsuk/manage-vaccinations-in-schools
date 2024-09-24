# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(FALSE), not null
#  reminder_sent_at   :datetime
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
  let(:programme) { create(:programme) }

  describe "#triage" do
    it "returns the triage records in ascending order" do
      patient_session = create(:patient_session, programme:)
      later_triage = create(:triage, programme:, patient_session:)
      earlier_triage =
        create(:triage, programme:, patient_session:, updated_at: 1.day.ago)

      expect(patient_session.triage).to eq [earlier_triage, later_triage]
    end
  end

  describe "#vaccine_record" do
    it "returns the last non-draft vaccination record" do
      patient_session = create(:patient_session, programme:)
      vaccination_record =
        create(:vaccination_record, programme:, patient_session:)
      vaccination_record.update!(recorded_at: 1.day.ago)
      draft_vaccination_record =
        create(:vaccination_record, programme:, patient_session:)
      draft_vaccination_record.update!(recorded_at: nil)

      expect(patient_session.vaccination_record).to eq vaccination_record
    end
  end

  describe "#latest_consents" do
    subject(:latest_consents) { patient_session.latest_consents }

    let(:patient_session) { create(:patient_session, programme:, patient:) }

    context "multiple consent given responses from different parents" do
      let(:parents) { create_list(:parent, 2, :recorded) }
      let(:consents) do
        [
          build(:consent, :recorded, :given, parent: parents.first, programme:),
          build(:consent, :recorded, :given, parent: parents.second, programme:)
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
      let(:parent) { create(:parent, :recorded) }
      let(:refused_consent) do
        build(:consent, :recorded, :refused, programme:, parent:)
      end
      let(:given_consent) do
        build(:consent, :recorded, :given, programme:, parent:)
      end
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

    context "multiple consent responses from same parent where one is draft" do
      let(:parent) { create(:parent, :recorded) }
      let(:refused_recorded_consent) do
        build(:consent, :recorded, :refused, programme:, parent:)
      end
      let(:given_draft_consent) do
        build(:consent, :draft, :given, programme:, parent:)
      end
      let(:patient) do
        create(
          :patient,
          parents: [parent],
          consents: [refused_recorded_consent, given_draft_consent]
        )
      end

      it "does not return a draft consent record" do
        expect(latest_consents).to eq [refused_recorded_consent]
      end
    end
  end

  describe "#latest_triage" do
    it "returns the latest triage record" do
      patient_session = create(:patient_session, programme:)
      create(
        :triage,
        programme:,
        status: :needs_follow_up,
        created_at: 1.day.ago,
        patient_session:
      )
      later_triage =
        create(
          :triage,
          programme:,
          status: :ready_to_vaccinate,
          patient_session:
        )

      expect(patient_session.latest_triage).to eq later_triage
    end
  end
end
