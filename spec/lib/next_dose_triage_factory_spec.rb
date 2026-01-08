# frozen_string_literal: true

describe NextDoseTriageFactory do
  subject(:call) { described_class.call(vaccination_record:) }

  let(:vaccination_record) { create(:vaccination_record, programme:) }

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
      expect(triage.performed_by).to be_nil
      expect(triage.team).to be_nil
    end

    context "when performed over 28 days ago" do
      let(:vaccination_record) do
        create(:vaccination_record, programme:, performed_at: 29.days.ago)
      end

      it "does not create a triage" do
        expect { call }.not_to(change(Triage, :count))
      end
    end
  end
end
