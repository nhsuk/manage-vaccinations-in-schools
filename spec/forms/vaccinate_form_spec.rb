# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it { should validate_length_of(:pre_screening_notes).is_at_most(1000) }
  end

  describe "patient attendance validation on confirmation" do
    let(:organisation) { create(:organisation) }
    let(:programme) do
      Programme.find_by(type: "hpv") || create(:programme, :hpv)
    end
    let(:session) do
      create(:session, :today, organisation:, programmes: [programme])
    end
    let(:user) { create(:user, organisation:) }
    let(:vaccine) { programme.vaccines.first }
    let(:batch) { create(:batch, organisation:, vaccine:) }
    let(:request_session) { {} }

    let(:draft_vaccination_record_attributes) do
      {
        outcome: "administered",
        notes: "Test vaccination notes",
        performed_at: Time.current,
        batch_id: batch.id,
        delivery_method: "intramuscular",
        delivery_site: "left_arm_upper_position",
        dose_sequence: 1,
        full_dose: true,
        patient_id: patient_session.patient.id,
        programme_id: programme.id,
        session_id: session.id
      }
    end

    let(:draft_vaccination_record) do
      DraftVaccinationRecord.new(
        request_session:,
        current_user: user,
        **draft_vaccination_record_attributes
      )
    end

    context "when patient is not attending the session" do
      let(:patient_session) { create(:patient_session, session:) }

      before do
        patient_session.registration_status ||
          create(
            :patient_session_registration_status,
            :unknown,
            patient_session:
          )

        draft_vaccination_record.wizard_step = :confirm
      end

      it "cannot register a vaccination for a patient not attending the session" do
        expect(draft_vaccination_record).not_to be_valid(:update)
        expect(draft_vaccination_record.errors[:session_id]).to include(
          match(/not registered as attending/)
        )
      end

      it "includes the patient name in the error message" do
        draft_vaccination_record.valid?(:update)

        expect(draft_vaccination_record.errors[:session_id]).to include(
          match(/#{patient_session.patient.full_name}/)
        )
      end
    end

    context "when patient is attending the session" do
      let(:patient_session) do
        create(:patient_session, :in_attendance, session:)
      end

      before { draft_vaccination_record.wizard_step = :confirm }

      it "can register a vaccination for a patient attending the session" do
        expect(draft_vaccination_record).to be_valid(:update)
      end
    end

    context "when patient has completed the session" do
      let(:patient_session) { create(:patient_session, session:) }

      before do
        create(
          :patient_session_registration_status,
          :completed,
          patient_session:
        )
        draft_vaccination_record.wizard_step = :confirm
      end

      it "can register a vaccination for a patient who has completed the session" do
        expect(draft_vaccination_record).to be_valid(:update)
      end
    end

    context "when patient is explicitly not attending" do
      let(:patient_session) { create(:patient_session, session:) }

      before do
        create(
          :patient_session_registration_status,
          :not_attending,
          patient_session:
        )
        draft_vaccination_record.wizard_step = :confirm
      end

      it "cannot register a vaccination for a patient explicitly not attending" do
        expect(draft_vaccination_record).not_to be_valid(:update)
        expect(draft_vaccination_record.errors[:session_id]).to include(
          match(/not registered as attending/)
        )
      end
    end
  end
end
