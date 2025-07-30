# frozen_string_literal: true

describe AcademicYear do
  before do
    Settings.academic_year_today_override = academic_year_today_override
    described_class.instance_variable_set(:@override_current_date, nil)
  end

  after do
    Settings.academic_year_today_override = nil
    described_class.instance_variable_set(:@override_current_date, nil)
  end

  let(:academic_year_today_override) { "" }

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

    context "when using the override setting" do
      let(:today) { Date.new(2024, 9, 1) }

      context "when set to nil" do
        let(:academic_year_today_override) { "nil" }

        it { should eq(2024) }
      end

      context "when set to a specific date" do
        let(:academic_year_today_override) { "2023-09-01" }

        it { should eq(2023) }
      end
    end
  end

  describe "#pending" do
    subject { travel_to(today) { described_class.pending } }

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

      it { should eq([2025, 2024]) }
    end

    context "first day of 2025" do
      let(:today) { Date.new(2025, 9, 1) }

      it { should eq([2025, 2024]) }
    end
  end
end
