# frozen_string_literal: true

describe PatientSession::Triage do
  subject(:instance) { described_class.new(patient_session) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }
  let(:patient_session) do
    create(:patient_session, programmes: [programme], patient:)
  end

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status.fetch(programme) }

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

  describe "#all" do
    subject(:all) { instance.all[programme] }

    let(:later_triage) { create(:triage, programme:, patient:) }
    let(:earlier_triage) do
      create(:triage, programme:, patient:, created_at: 1.day.ago)
    end

    it { should eq([earlier_triage, later_triage]) }
  end

  describe "#latest" do
    subject(:latest) { instance.latest[programme] }

    let(:later_triage) do
      create(
        :triage,
        created_at: 1.day.ago,
        programme:,
        status: :ready_to_vaccinate,
        patient:
      )
    end

    before do
      create(
        :triage,
        programme:,
        status: :needs_follow_up,
        created_at: 2.days.ago,
        patient:
      )

      # should not be returned as invalidated even if more recent
      create(
        :triage,
        :invalidated,
        programme:,
        status: :ready_to_vaccinate,
        patient:
      )
    end

    it { should eq(later_triage) }
  end
end
