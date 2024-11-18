# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_sessions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  patient_id          :bigint           not null
#  proposed_session_id :bigint
#  session_id          :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_proposed_session_id        (proposed_session_id)
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (proposed_session_id => sessions.id)
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

  describe "#latest_consents" do
    subject(:latest_consents) { patient_session.latest_consents }

    let(:patient_session) { create(:patient_session, programme:, patient:) }

    context "multiple consent given responses from different parents" do
      let(:parents) { create_list(:parent, 2) }
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
      let(:parent) { create(:parent) }
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
      let(:parent) { create(:parent) }
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

    context "with an invalidated consent" do
      let(:parent) { create(:parent) }
      let(:invalidated_consent) do
        build(:consent, :recorded, :given, :invalidated, programme:, parent:)
      end
      let(:patient) do
        create(:patient, parents: [parent], consents: [invalidated_consent])
      end

      it "does not return the consent record" do
        expect(latest_consents).not_to include(invalidated_consent)
      end
    end
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

  describe "#confirm_transfer!" do
    subject(:confirm_transfer!) { patient_session.confirm_transfer! }

    let(:original_session) { create(:session, programme:) }
    let(:proposed_session) { create(:session, programme:) }
    let(:patient_session) do
      create(
        :patient_session,
        programme:,
        session: original_session,
        proposed_session:
      )
    end

    it "destroys the patient session, creates one with the proposed session" do
      # stree-ignore
      expect { confirm_transfer! }
        .to change { patient_session.patient.reload.school }
          .from(original_session.location).to(proposed_session.location)
        .and change { described_class.exists?(patient_session.id) }
          .from(true).to(false)
        .and not_change(patient_session.patient.patient_sessions, :count)
    end

    context "when there is no proposed session" do
      let(:patient_session) { create(:patient_session, programme:) }

      it "does not change the session" do
        expect { confirm_transfer! }.not_to change(patient_session, :session)
      end
    end

    context "when the patient session has vaccination records" do
      before { create(:vaccination_record, programme:, patient_session:) }

      it "does not change the sesion, creates a new patient session" do
        # stree-ignore
        expect { confirm_transfer! }
          .to change(patient_session, :proposed_session).to(nil)
          .and not_change(patient_session, :session)
          .and change(patient_session.patient.patient_sessions, :count).by(1)
          .and change { patient_session.patient.reload.school }
            .from(original_session.location).to(proposed_session.location)
      end
    end

    context "when the patient session is for the generic clinic" do
      let(:organisation) { original_session.organisation }
      let(:location) { create(:location, :generic_clinic, organisation:) }
      let(:proposed_session) do
        create(:session, location:, organisation:, programme:)
      end

      it "updates the patient's school to nil" do
        expect { confirm_transfer! }.to change(
          patient_session.patient,
          :school
        ).to(nil)
      end
    end
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
