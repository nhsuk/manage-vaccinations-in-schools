# frozen_string_literal: true

describe NextDoseTriageFactory do
  subject(:call) { described_class.call(vaccination_record:, current_user:) }

  let(:vaccination_record) { create(:vaccination_record, session:, programme:) }
  let(:current_user) { create(:nurse) }

  let(:session) { create(:session, programmes: [programme]) }

  context "with a single dose programme" do
    let(:programme) { Programme.hpv }

    it "does not create a triage" do
      expect { call }.not_to(change(Triage, :count))
    end
  end

  context "with the MMR programme" do
    let(:programme) { Programme.mmr }

    it "creates a triage" do
      expect { call }.to change(Triage, :count).by(1)

      triage = vaccination_record.reload.next_dose_delay_triage
      expect(triage).to be_delay_vaccination
      expect(triage.delay_vaccination_until).to eq(28.days.from_now.to_date)
    end

    context "when not recorded in the service" do
      let(:session) { nil }

      it "does not create a triage" do
        expect { call }.not_to(change(Triage, :count))
      end
    end
  end
end
