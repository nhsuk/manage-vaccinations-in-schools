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
  let(:session) { create(:session, organisation:, programmes: [programme]) }
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

    context "on notes step" do
      let(:attributes) { valid_administered_attributes }

      before { draft_vaccination_record.wizard_step = :notes }

      it { should validate_length_of(:notes).is_at_most(1000).on(:update) }
    end

    context "on confirm step" do
      let(:attributes) { valid_administered_attributes }

      before { draft_vaccination_record.wizard_step = :confirm }

      it { should validate_length_of(:notes).is_at_most(1000).on(:update) }
    end

    context "on delivery step" do
      let(:attributes) { valid_administered_attributes }

      before { draft_vaccination_record.wizard_step = :delivery }

      context "when delivery site is blank" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "intramuscular",
            delivery_site: nil
          )
        end

        it "has an error for blank delivery site" do
          expect(draft_vaccination_record.save(context: :update)).to be(false)
          expect(draft_vaccination_record.errors[:delivery_site]).to include(
            "Choose a delivery site"
          )
        end
      end

      context "when delivery method is nasal spray" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "nasal_spray",
            delivery_site: "left_arm_upper_position"
          )
        end

        it "has an error when delivery site is not nose" do
          expect(draft_vaccination_record.save(context: :update)).to be(false)
          expect(draft_vaccination_record.errors[:delivery_site]).to include(
            "Site must be nose if the nasal spray was given"
          )
        end
      end

      context "when delivery method is nasal spray and delivery site is nose" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "nasal_spray",
            delivery_site: "nose"
          )
        end

        it "is valid" do
          expect(draft_vaccination_record.save(context: :update)).to be(true)
          expect(draft_vaccination_record.errors[:delivery_site]).to be_empty
        end
      end

      context "when delivery method is intramuscular" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "intramuscular",
            delivery_site: "nose"
          )
        end

        it "has an error when delivery site is nose" do
          expect(draft_vaccination_record.save(context: :update)).to be(false)
          expect(draft_vaccination_record.errors[:delivery_site]).to include(
            "Site cannot be nose for intramuscular or subcutaneous injections"
          )
        end
      end

      context "when delivery method is subcutaneous" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "subcutaneous",
            delivery_site: "nose"
          )
        end

        it "has an error when delivery site is nose" do
          expect(draft_vaccination_record.save(context: :update)).to be(false)
          expect(draft_vaccination_record.errors[:delivery_site]).to include(
            "Site cannot be nose for intramuscular or subcutaneous injections"
          )
        end
      end

      context "when delivery method is intramuscular and delivery site is not nose" do
        let(:attributes) do
          valid_administered_attributes.merge(
            delivery_method: "intramuscular",
            delivery_site: "left_arm_upper_position"
          )
        end

        it "is valid" do
          expect(draft_vaccination_record.save(context: :update)).to be(true)
          expect(draft_vaccination_record.errors[:delivery_site]).to be_empty
        end
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

    context "when administered" do
      let(:attributes) { valid_administered_attributes.except(:full_dose) }

      it "sets full dose to true if half doses cannot be recorded" do
        expect { save! }.to change(draft_vaccination_record, :full_dose).to(
          true
        )
      end
    end

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
    subject { draft_vaccination_record.dose_volume_ml }

    let(:attributes) { valid_administered_attributes }

    it { should eq(vaccine.dose_volume_ml) }

    context "with a half dose" do
      let(:attributes) { valid_administered_attributes.merge(full_dose: false) }

      it { should eq(vaccine.dose_volume_ml * 0.5) }
    end
  end

  describe "#delivery_method=" do
    context "when setting delivery method for the first time" do
      let(:attributes) do
        valid_administered_attributes.except(:delivery_method)
      end

      it "does not clear the batch_id" do
        expect {
          draft_vaccination_record.delivery_method = "intramuscular"
        }.not_to change(draft_vaccination_record, :batch_id)
      end
    end

    shared_examples "clears batch when switching delivery methods" do |from_method, to_method|
      context "when changing from #{from_method} to #{to_method}" do
        let(:attributes) do
          valid_administered_attributes.merge(delivery_method: from_method)
        end

        it "clears the batch_id" do
          expect {
            draft_vaccination_record.delivery_method = to_method
          }.to change(draft_vaccination_record, :batch_id).to(nil)
        end
      end
    end

    include_examples "clears batch when switching delivery methods",
                     "intramuscular",
                     "nasal_spray"
    include_examples "clears batch when switching delivery methods",
                     "subcutaneous",
                     "nasal_spray"
    include_examples "clears batch when switching delivery methods",
                     "nasal_spray",
                     "intramuscular"
    include_examples "clears batch when switching delivery methods",
                     "nasal_spray",
                     "subcutaneous"

    context "when changing between injection methods" do
      let(:attributes) do
        valid_administered_attributes.merge(delivery_method: "intramuscular")
      end

      it "does not clear the batch_id" do
        expect {
          draft_vaccination_record.delivery_method = "subcutaneous"
        }.not_to change(draft_vaccination_record, :batch_id)
      end
    end
  end
end
