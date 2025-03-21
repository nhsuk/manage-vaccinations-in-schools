# frozen_string_literal: true

describe Patient::ProgrammeOutcome do
  subject(:instance) { described_class.new(patient) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status[programme] }

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

  describe "#all" do
    subject(:all) { instance.all[programme] }

    let(:later_vaccination_record) do
      create(:vaccination_record, patient:, programme:)
    end
    let(:earlier_vaccination_record) do
      create(:vaccination_record, patient:, programme:, created_at: 1.day.ago)
    end

    it { should eq([earlier_vaccination_record, later_vaccination_record]) }
  end
end
