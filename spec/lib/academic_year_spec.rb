# frozen_string_literal: true

describe AcademicYear do
  describe "#all" do
    subject { travel_to(today) { described_class.all } }

    context "in 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq([2024]) }
    end

    context "in 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq([2024, 2025]) }
    end
  end

  describe "#current" do
    subject { travel_to(today) { described_class.current } }

    context "in 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "in 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2025) }
    end
  end

  describe "#first" do
    subject { travel_to(today) { described_class.first } }

    context "in 2023" do
      let(:today) { Date.new(2023, 9, 1) }

      it { should eq(2023) }
    end

    context "in 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "in 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2024) }
    end
  end

  describe "#last" do
    subject { travel_to(today) { described_class.last } }

    context "in 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "in 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2025) }
    end
  end
end
