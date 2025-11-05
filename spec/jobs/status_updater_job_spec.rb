# frozen_string_literal: true

describe StatusUpdaterJob do
  describe "#perform_now" do
    subject(:perform_now) { described_class.perform_now(patient:, session:) }

    let(:patient) { build(:patient) }
    let(:session) { build(:session) }

    context "during the preparation period" do
      around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

      it "calls the service class with the current and pending academic years" do
        expect(StatusUpdater).to receive(:call).with(
          patient:,
          session:,
          academic_years: [2024, 2025]
        )

        perform_now
      end
    end

    context "outside the preparation period" do
      around { |example| travel_to(Date.new(2025, 9, 1)) { example.run } }

      it "calls the service class with the current and pending academic years" do
        expect(StatusUpdater).to receive(:call).with(
          patient:,
          session:,
          academic_years: [2025]
        )

        perform_now
      end
    end
  end
end
