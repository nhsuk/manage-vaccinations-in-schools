# frozen_string_literal: true

describe TriageOutcome do
  subject(:instance) do
    described_class.new(
      patients: Patient.all,
      vaccinated_criteria: VaccinatedCriteria.new(patients: Patient.all)
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  # TODO: Remove once ConsentOutcome is refactored
  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status(patient, programme:) }

    context "with no triage" do
      it { should be(described_class::NOT_REQUIRED) }
    end

    context "with a consent that needs triage" do
      before { create(:consent, :given, :needing_triage, patient:, programme:) }

      it { should be(described_class::REQUIRED) }
    end

    context "with a safe to vaccinate triage" do
      before { create(:triage, :ready_to_vaccinate, patient:, programme:) }

      it { should be(described_class::SAFE_TO_VACCINATE) }
    end

    context "with a do not vaccinate triage" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(described_class::DO_NOT_VACCINATE) }
    end

    context "with a needs follow up triage" do
      before { create(:triage, :needs_follow_up, patient:, programme:) }

      it { should be(described_class::REQUIRED) }
    end

    context "with a delay vaccination triage" do
      before { create(:triage, :delay_vaccination, patient:, programme:) }

      it { should be(described_class::DELAY_VACCINATION) }
    end

    context "with an invalidated safe to vaccinate triage" do
      before do
        create(:triage, :ready_to_vaccinate, :invalidated, patient:, programme:)
      end

      it { should be(described_class::NOT_REQUIRED) }
    end
  end
end
