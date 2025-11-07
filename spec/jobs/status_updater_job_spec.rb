# frozen_string_literal: true

describe StatusUpdaterJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(patient.id) }

    let(:patient) { create(:patient) }

    context "during the preparation period" do
      around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

      it "calls the service class with the current and pending academic years" do
        expect(StatusUpdater).to receive(:call).with(
          patient:,
          academic_years: [2024, 2025]
        )

        perform
      end
    end

    context "outside the preparation period" do
      around { |example| travel_to(Date.new(2025, 9, 1)) { example.run } }

      it "calls the service class with the current and pending academic years" do
        expect(StatusUpdater).to receive(:call).with(
          patient:,
          academic_years: [2025]
        )

        perform
      end
    end
  end
end
