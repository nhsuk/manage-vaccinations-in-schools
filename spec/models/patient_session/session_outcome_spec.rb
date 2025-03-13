# frozen_string_literal: true

describe PatientSession::SessionOutcome do
  subject(:instance) { described_class.new(patient_session) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient_session) { create(:patient_session, patient:, session:) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status[programme] }

    context "with no vaccination record" do
      it { should be(described_class::NONE_YET) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, session:, programme:) }

      it { should be(described_class::VACCINATED) }
    end

    context "with a vaccination not administered" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(described_class::UNWELL) }
    end

    context "with a discarded vaccination administered" do
      before do
        create(:vaccination_record, :discarded, patient:, session:, programme:)
      end

      it { should be(described_class::NONE_YET) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(described_class::REFUSED) }
    end

    context "when triaged as do not vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(described_class::HAD_CONTRAINDICATIONS) }
    end
  end

  describe "#all" do
    subject(:all) { instance.all[programme] }

    let(:later_vaccination_record) do
      create(:vaccination_record, patient:, session:, programme:)
    end
    let(:earlier_vaccination_record) do
      create(
        :vaccination_record,
        patient:,
        session:,
        programme:,
        created_at: 1.day.ago
      )
    end

    it { should eq([earlier_vaccination_record, later_vaccination_record]) }
  end

  describe "#latest" do
    subject(:latest) { instance.latest[programme] }

    let(:later_vaccination_record) do
      create(
        :vaccination_record,
        created_at: 1.day.ago,
        patient:,
        session:,
        programme:
      )
    end

    before do
      create(
        :vaccination_record,
        created_at: 2.days.ago,
        patient:,
        session:,
        programme:
      )

      # should not be returned as discarded even if more recent
      create(:vaccination_record, :discarded, patient:, session:, programme:)
    end

    it { should eq(later_vaccination_record) }
  end
end
