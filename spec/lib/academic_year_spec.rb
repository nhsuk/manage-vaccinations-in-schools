# frozen_string_literal: true

describe AcademicYear do
  describe "#all" do
    subject { travel_to(today) { described_class.all } }

    context "first day of 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq([2024]) }
    end

    context "last day of only 2024" do
      let(:today) { Date.new(2025, 7, 31) }

      it { should eq([2024]) }
    end

    context "preparing for 2025" do
      let(:today) { Date.new(2025, 8, 1) }

      it { should eq([2024, 2025]) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq([2024, 2025]) }
    end
  end

  describe "#current" do
    subject { travel_to(today) { described_class.current } }

    context "first day of 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2025) }
    end
  end

  describe "#first" do
    subject { travel_to(today) { described_class.first } }

    context "first day of 2023" do
      let(:today) { Date.new(2023, 9, 1) }

      it { should eq(2023) }
    end

    context "first day of 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2024) }
    end
  end

  describe "#last" do
    subject { travel_to(today) { described_class.last } }

    context "first day of 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should eq(2024) }
    end

    context "last day of only 2024" do
      let(:today) { Date.new(2025, 7, 31) }

      it { should eq(2024) }
    end

    context "preparing for 2025" do
      let(:today) { Date.new(2025, 8, 1) }

      it { should eq(2025) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq(2025) }
    end
  end

  describe "#preparation?" do
    subject { travel_to(today) { described_class.preparation? } }

    context "first day of 2024" do
      let(:today) { Date.new(2024, 9, 1) }

      it { should be(false) }
    end

    context "last day of only 2024" do
      let(:today) { Date.new(2025, 7, 31) }

      it { should be(false) }
    end

    context "preparing for 2025" do
      let(:today) { Date.new(2025, 8, 1) }

      it { should be(true) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should be(false) }
    end
  end
end
