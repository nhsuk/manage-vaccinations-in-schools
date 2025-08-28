# frozen_string_literal: true

describe VaccinateForm do
  subject(:form) { described_class.new(programme:) }

  let(:programme) { create(:programme) }

  describe "validations" do
    it do
      expect(form).to allow_values(true, false).for(
        :identity_check_confirmed_by_patient
      )
    end

    it do
      expect(form).to validate_length_of(
        :identity_check_confirmed_by_other_name
      ).is_at_most(300)
    end

    it do
      expect(form).to validate_length_of(
        :identity_check_confirmed_by_other_relationship
      ).is_at_most(300)
    end

    context "when confirmed by someone else" do
      subject(:form) do
        described_class.new(
          identity_check_confirmed_by_patient: false,
          programme:
        )
      end

      it do
        expect(form).to validate_presence_of(
          :identity_check_confirmed_by_other_name
        )
      end

      it do
        expect(form).to validate_presence_of(
          :identity_check_confirmed_by_other_relationship
        )
      end
    end

    it { should validate_length_of(:pre_screening_notes).is_at_most(1000) }
  end

  describe "patient attendance validation on confirmation" do
    let(:team) { create(:team) }
    let(:programme) { create(:programme, :hpv) }
    let(:session) { create(:session, :today, team:, programmes: [programme]) }
    let(:user) { create(:user, team:) }
    let(:vaccine) { programme.vaccines.first }
    let(:batch) { create(:batch, team:, vaccine:) }
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
          create(
            :patient_session_registration_status,
            :unknown,
            patient_session:
          )

        draft_vaccination_record.wizard_step = :confirm
      end

      it "cannot register a vaccination" do
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

      it "can register a vaccination" do
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

      it "can register a vaccination" do
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

      it "cannot register a vaccination" do
        expect(draft_vaccination_record).not_to be_valid(:update)
        expect(draft_vaccination_record.errors[:session_id]).to include(
          match(/not registered as attending/)
        )
      end
    end
  end
end
