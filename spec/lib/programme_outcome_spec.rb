# frozen_string_literal: true

describe ProgrammeOutcome do
  subject(:instance) do
    described_class.new(
      patients: Patient.all,
      consent_outcome:,
      triage_outcome:,
      vaccinated_criteria:
    )
  end

  let(:consent_outcome) { ConsentOutcome.new(patients: Patient.all) }
  let(:triage_outcome) do
    TriageOutcome.new(
      patients: Patient.all,
      consent_outcome:,
      vaccinated_criteria:
    )
  end
  let(:vaccinated_criteria) { VaccinatedCriteria.new(patients: Patient.all) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  describe "#status" do
    subject(:status) { instance.status(patient, programme:) }

    context "with no vaccination record" do
      it { should be(described_class::NONE_YET) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, programme:) }

      it { should be(described_class::VACCINATED) }
    end

    context "with a vaccination already had" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          :already_had,
          patient:,
          programme:
        )
      end

      it { should be(described_class::VACCINATED) }
    end

    context "with a vaccination not administered" do
      before do
        create(:vaccination_record, :not_administered, patient:, programme:)
      end

      it { should be(described_class::NONE_YET) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(described_class::COULD_NOT_VACCINATE) }
    end

    context "with a triage as unsafe to vaccination" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(described_class::COULD_NOT_VACCINATE) }
    end

    context "with a discarded vaccination administered" do
      before { create(:vaccination_record, :discarded, patient:, programme:) }

      it { should be(described_class::NONE_YET) }
    end
  end
end
