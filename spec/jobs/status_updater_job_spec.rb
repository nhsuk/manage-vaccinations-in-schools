# frozen_string_literal: true

describe StatusUpdaterJob do
  describe "#perform_now" do
    subject(:perform_now) { described_class.perform_now(patient:, session:) }

    let(:patient) { build(:patient) }
    let(:session) { build(:session) }

    it "calls the service class" do
      expect(StatusUpdater).to receive(:call).with(patient:, session:)
      perform_now
    end
  end
end
