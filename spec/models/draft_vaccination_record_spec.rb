# frozen_string_literal: true

describe DraftVaccinationRecord do
  subject(:draft_vaccination_record) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:organisation) do
    create(:organisation, :with_one_nurse, programmes: [programme])
  end

  let(:request_session) { {} }
  let(:current_user) { organisation.users.first }

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }
  let(:vaccine) { programme.vaccines.first }
  let(:batch) { create(:batch, organisation:, vaccine:) }

  let(:valid_administered_attributes) do
    {
      performed_at: Time.zone.local(2024, 11, 1, 12),
      batch_id: batch.id,
      delivery_method: "intramuscular",
      delivery_site: "left_arm_upper_position",
      dose_sequence: 1,
      full_dose: true,
      notes: "Some notes.",
      outcome: "administered",
      patient_id: patient.id,
      programme_id: programme.id,
      session_id: session.id
    }
  end

  let(:valid_not_administered_attributes) do
    {
      notes: "Some notes.",
      patient_id: patient.id,
      programme_id: programme.id,
      session_id: session.id,
      outcome: "unwell"
    }
  end

  let(:invalid_attributes) { {} }

  describe "validations" do
    context "when performed_at is in the future" do
      let(:attributes) do
        valid_administered_attributes.merge(performed_at: 1.second.from_now)
      end

      around { |example| freeze_time { example.run } }

      before { draft_vaccination_record.wizard_step = :date_and_time }

      it "has an error" do
        expect(draft_vaccination_record.save(context: :update)).to be(false)
        expect(draft_vaccination_record.errors[:performed_at]).to include(
          "Enter a time in the past"
        )
      end
    end
  end

  describe "#write_to!" do
    subject(:write_to!) do
      draft_vaccination_record.write_to!(vaccination_record)
    end

    let(:attributes) { valid_administered_attributes }

    let(:vaccination_record) { VaccinationRecord.new }

    it "sets the vaccine" do
      expect { write_to! }.to change(vaccination_record, :vaccine).to(
        batch.vaccine
      )
    end
  end

  describe "#reset_unused_fields" do
    subject(:save!) { draft_vaccination_record.save! }

    context "when not administered" do
      let(:attributes) do
        valid_not_administered_attributes.merge(
          valid_administered_attributes.except(:outcome)
        )
      end

      it "clears the batch" do
        expect { save! }.to change(draft_vaccination_record, :batch_id).to(nil)
      end

      it "clears the deliver method" do
        expect { save! }.to change(
          draft_vaccination_record,
          :delivery_method
        ).to(nil)
      end

      it "clears the deliver site" do
        expect { save! }.to change(draft_vaccination_record, :delivery_site).to(
          nil
        )
      end
    end
  end

  describe "#dose_volume_ml" do
    let(:attributes) { valid_administered_attributes }

    it "determines the dose volume in ml from the vaccine" do
      expect(draft_vaccination_record.dose_volume_ml).to eq(
        vaccine.dose_volume_ml
      )
    end
  end
end
