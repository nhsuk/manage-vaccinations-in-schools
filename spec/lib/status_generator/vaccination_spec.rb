# frozen_string_literal: true

describe StatusGenerator::Vaccination do
  subject(:generator) do
    described_class.new(
      programme:,
      academic_year: AcademicYear.current,
      patient:,
      consents: patient.consents,
      triages: patient.triages,
      vaccination_records: patient.vaccination_records
    )
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme, :hpv) }

  describe "#status" do
    subject { generator.status }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, programme:) }

      it { should be(:vaccinated) }
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

      it { should be(:vaccinated) }
    end

    context "with a vaccination not administered" do
      before do
        create(:vaccination_record, :not_administered, patient:, programme:)
      end

      it { should be(:none_yet) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:could_not_vaccinate) }
    end

    context "with a triage as unsafe to vaccination" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:could_not_vaccinate) }
    end

    context "with a discarded vaccination administered" do
      before { create(:vaccination_record, :discarded, patient:, programme:) }

      it { should be(:none_yet) }
    end
  end
end
