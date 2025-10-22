# frozen_string_literal: true

describe TriageForm do
  subject(:form) { described_class.new(patient:, session:, programme:) }

  let(:programme) { create(:programme) }
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
        status_option: "safe_to_vaccinate"
      )
    end

    let(:programme) { create(:programme, :hpv) }
    let(:patient) { create(:patient, :consent_given_triage_needed, session:) }

    it "sets the vaccine method to injection" do
      triage = form.save!

      expect(triage.vaccine_method).to eq("injection")
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

    let(:programme) { create(:programme, :flu) }
    let(:patient) do
      create(:patient, :consent_given_nasal_only_triage_needed, session:)
    end

    it "sets the vaccine method to nasal" do
      triage = form.save!

      expect(triage.vaccine_method).to eq("nasal")
      expect(triage.notes).to eq("test")
    end
  end
end
