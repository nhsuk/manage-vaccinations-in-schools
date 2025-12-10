# frozen_string_literal: true

describe YearGroupsHelper do
  describe "#format_year_group" do
    subject { helper.format_year_group(year_group) }

    context "when the year group is negative" do
      let(:year_group) { -1 }

      it { should eq("Nursery (2nd year)") }
    end

    context "when the year group is zero" do
      let(:year_group) { 0 }

      it { should eq("Reception") }
    end

    context "when the year group is positive" do
      let(:year_group) { 1 }

      it { should eq("Year 1") }
    end
  end

  describe "#format_year_groups" do
    subject { helper.format_year_groups(year_groups) }

    context "with one year group" do
      let(:year_groups) { [1] }

      it { should eq("Year 1") }
    end

    context "with multiple continuous year groups" do
      let(:year_groups) { [1, 2, 3, 4] }

      it { should eq("Years 1 to 4") }
    end

    context "with multiple non-continuous year groups" do
      let(:year_groups) { [1, 2, 4] }

      it { should eq("Years 1, 2, and 4") }
    end

    context "with reception and other year groups" do
      let(:year_groups) { [0, 1, 2] }

      it { should eq("Reception and years 1 and 2") }
    end

    context "with nursery and reception" do
      let(:year_groups) { [-1, 0, 1, 2] }

      it { should eq("Nursery (2nd year), reception and years 1 and 2") }
    end
  end
end
