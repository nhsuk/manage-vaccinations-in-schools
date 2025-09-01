# frozen_string_literal: true

describe TriageForm do
  subject(:form) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }

  describe "validations" do
    it do
      expect(form).to validate_inclusion_of(
        :status_and_vaccine_method
      ).in_array(form.status_and_vaccine_method_options)
    end

    it { should_not validate_presence_of(:notes) }
    it { should_not validate_presence_of(:vaccine_methods) }
    it { should validate_length_of(:notes).is_at_most(1000) }
    it { should allow_values(true, false).for(:add_psd) }
  end

  describe "when the patient is safe to vaccinate for HPV" do
    subject(:form) do
      described_class.new(
        patient_session:,
        programme:,
        current_user: create(:user),
        notes: "test",
        status_and_vaccine_method: "safe_to_vaccinate"
      )
    end

    let(:programme) { create(:programme, :hpv) }
    let(:patient_session) do
      create(
        :patient_session,
        :consent_given_triage_needed,
        programmes: [programme]
      )
    end

    it "sets the vaccine method to injection" do
      form.save!

      triage = patient_session.reload.patient.triages.last
      expect(triage.vaccine_method).to eq("injection")
    end
  end

  describe "when the patient has a nasal only consent" do
    subject(:form) do
      described_class.new(
        patient_session:,
        programme:,
        current_user: create(:user),
        notes: "test",
        status_and_vaccine_method: "safe_to_vaccinate_nasal"
      )
    end

    let(:programme) { create(:programme, :flu) }
    let(:patient_session) do
      create(
        :patient_session,
        :consent_given_nasal_only_triage_needed,
        programmes: [programme]
      )
    end

    it "sets the vaccine method to nasal" do
      form.save!

      triage = patient_session.reload.patient.triages.last
      expect(triage.vaccine_method).to eq("nasal")
      expect(triage.notes).to eq("test")
    end
  end
end
