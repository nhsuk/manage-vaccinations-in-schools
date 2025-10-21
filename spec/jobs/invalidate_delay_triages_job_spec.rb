# frozen_string_literal: true

describe InvalidateDelayTriagesJob do
  subject(:perform_now) { described_class.perform_now }

  context "with a triage as safe to vaccinate" do
    let!(:triage) { create(:triage, :safe_to_vaccinate) }

    it "does not invalidate the triage" do
      expect { perform_now }.not_to(change { triage.reload.invalidated? })
    end

    it "does not update the statuses" do
      expect(StatusUpdater).not_to receive(:call)
      perform_now
    end
  end

  context "with a triage that delays until today" do
    let!(:triage) do
      create(:triage, :delay_vaccination, delay_vaccination_until: Date.current)
    end

    it "does not invalidate the triage" do
      expect { perform_now }.not_to(change { triage.reload.invalidated? })
    end

    it "does not update the statuses" do
      expect(StatusUpdater).not_to receive(:call)
      perform_now
    end
  end

  context "with a triage that delays until yesterday" do
    let!(:triage) do
      create(
        :triage,
        :delay_vaccination,
        delay_vaccination_until: Date.yesterday
      )
    end

    it "invalidates the triage" do
      expect { perform_now }.to change { triage.reload.invalidated? }.from(
        false
      ).to(true)
    end

    it "updates the statuses" do
      expect(StatusUpdater).to receive(:call).with(patient: [triage.patient_id])
      perform_now
    end
  end

  context "with a triage that delays until yesterday but is already invalidated" do
    let!(:triage) do
      create(
        :triage,
        :delay_vaccination,
        :invalidated,
        delay_vaccination_until: Date.yesterday
      )
    end

    it "does not invalidate the triage" do
      expect { perform_now }.not_to(change { triage.reload.invalidated? })
    end

    it "does not update the statuses" do
      expect(StatusUpdater).not_to receive(:call)
      perform_now
    end
  end
end
