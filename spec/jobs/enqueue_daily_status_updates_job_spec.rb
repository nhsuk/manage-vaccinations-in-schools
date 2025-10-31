# frozen_string_literal: true

describe EnqueueDailyStatusUpdatesJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    let(:patients) { create_list(:patient, 2, session:) }
    let(:session) { create(:session) }

    it "enqueues StatusUpdaterJob with patient IDs from each batch" do
      expect(StatusUpdaterJob).to receive(:perform_later).with(
        patient: patients.map(&:id)
      )
      perform
    end
  end
end
