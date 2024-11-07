# frozen_string_literal: true

describe DraftVaccinationRecord do
  subject(:draft_vaccination_record) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:request_session) { {} }
  let(:current_user) { create(:user) }

  let(:patient_session) { create(:patient_session) }
  let(:programme) { patient_session.programmes.first }
  let(:vaccine) { programme.vaccines.first }
  let(:batch) { create(:batch, vaccine:) }

  let(:valid_administered_attributes) do
    {
      administered_at: Time.zone.local(2024, 11, 1, 12),
      batch_id: batch.id,
      delivery_method: "intramuscular",
      delivery_site: "left_arm",
      dose_sequence: 1,
      notes: "Some notes.",
      patient_session_id: patient_session.id,
      programme_id: programme.id,
      vaccine_id: vaccine.id
    }
  end

  let(:valid_not_administered_attributes) do
    {
      notes: "Some notes.",
      patient_session_id: patient_session.id,
      programme_id: programme.id,
      reason: "unwell"
    }
  end

  let(:invalid_attributes) { {} }

  describe "validations" do
    context "vaccine and batch doesn't match" do
      let(:different_vaccine) { create(:vaccine, programme:) }
      let(:different_batch) { create(:batch, vaccine: different_vaccine) }

      let(:attributes) do
        valid_administered_attributes.merge(batch_id: different_batch.id)
      end

      before { draft_vaccination_record.wizard_step = :batch }

      it "has an error" do
        expect(draft_vaccination_record.save(context: :update)).to be(false)
        expect(draft_vaccination_record.errors[:batch_id]).to include(
          /Choose a batch/
        )
      end
    end
  end

  describe "#reset_unused_fields" do
    subject(:save!) { draft_vaccination_record.save! }

    context "when administered" do
      let(:attributes) do
        valid_administered_attributes.merge(valid_not_administered_attributes)
      end

      it "clears the reason" do
        expect { save! }.to change(draft_vaccination_record, :reason).to(nil)
      end
    end

    context "when not administered" do
      let(:attributes) do
        valid_not_administered_attributes.merge(
          valid_administered_attributes.except(:administered_at)
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

      it "clears the vaccine" do
        expect { save! }.to change(draft_vaccination_record, :vaccine_id).to(
          nil
        )
      end
    end
  end
end
