# frozen_string_literal: true

describe TriageForm do
  subject(:form) { described_class.new(patient:, session:, programme:) }

  let(:programme) { CachedProgramme.sample }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(:status_option).in_array(
        form.status_options
      )
    end

    it { should_not validate_presence_of(:notes) }
    it { should_not validate_presence_of(:consent_vaccine_methods) }
    it { should validate_length_of(:notes).is_at_most(1000) }
    it { should allow_values(true, false).for(:add_patient_specific_direction) }
  end

  describe "when the patient is safe to vaccinate for HPV" do
    subject(:form) do
      described_class.new(
        patient:,
        session:,
        programme:,
        current_user: create(:user),
        notes: "test",
        status_option: "safe_to_vaccinate",
        delay_vaccination_until:
      )
    end

    let(:programme) { CachedProgramme.hpv }
    let(:patient) { create(:patient, :consent_given_triage_needed, session:) }
    let(:delay_vaccination_until) { nil }

    it "sets the vaccine method to injection" do
      triage = form.save!

      expect(triage.vaccine_method).to eq("injection")
    end

    context "and delay vaccination until is set" do
      let(:delay_vaccination_until) { Date.tomorrow }

      it "ignores it" do
        triage = form.save!

        expect(triage.delay_vaccination_until).to be_nil
      end
    end
  end

  describe "when the patient has a nasal only consent" do
    subject(:form) do
      described_class.new(
        patient:,
        session:,
        programme:,
        current_user: create(:user),
        notes: "test",
        status_option: "safe_to_vaccinate_nasal"
      )
    end

    let(:programme) { CachedProgramme.flu }
    let(:patient) do
      create(:patient, :consent_given_nasal_only_triage_needed, session:)
    end

    it "sets the vaccine method to nasal" do
      triage = form.save!

      expect(triage.vaccine_method).to eq("nasal")
      expect(triage.notes).to eq("test")
    end
  end

  describe "when the patient has a delayed vaccination for MMR" do
    subject(:form) do
      described_class.new(
        patient:,
        session:,
        programme:,
        current_user: create(:user),
        notes: "test",
        status_option: "delay_vaccination",
        delay_vaccination_until: Date.tomorrow
      )
    end

    let(:programme) { CachedProgramme.mmr }
    let(:patient) { create(:patient, :consent_given_triage_needed, session:) }
    let(:vaccination_record) do
      create(:vaccination_record, patient:, programme:)
    end

    it "associates the triage with the vaccination record" do
      vaccination_record = create(:vaccination_record, patient:, programme:)

      triage = form.save!

      expect(vaccination_record.reload.next_dose_delay_triage).to eq(triage)
    end
  end

  context "programme is MMR" do
    let(:programme) { CachedProgramme.mmr }

    describe "validation for delay_vaccination_until" do
      subject(:validation_errors) do
        form.save # rubocop:disable Rails/SaveBang
        form.errors.full_messages
      end

      let(:delay_vaccination_until) { nil }

      let(:form) do
        described_class.new(
          patient:,
          session:,
          programme:,
          delay_vaccination_until:,
          current_user: create(:user),
          status_option: "delay_vaccination"
        )
      end

      context "patient hasn't received any doses" do
        let(:delay_vaccination_until) { Date.tomorrow }

        it "doesn't produce any validation errors" do
          expect(validation_errors).to be_empty
        end
      end

      context "patient has had their first dose" do
        let(:delay_vaccination_until) { Date.tomorrow }
        let(:expected_mmr_next_dose) do
          (vaccination_record.performed_at + 28.days).to_date
        end

        let!(:vaccination_record) do
          create(
            :vaccination_record,
            patient:,
            programme:,
            session:,
            performed_at: 1.week.ago
          )
        end

        before { StatusUpdater.call(patient:) }

        it "produces validation errors" do
          expect(validation_errors.join).to include(
            "The vaccination cannot take place before #{expected_mmr_next_dose.to_fs(:long)}"
          )
        end
      end
    end
  end
end
