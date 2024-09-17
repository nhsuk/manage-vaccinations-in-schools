# frozen_string_literal: true

RSpec.describe CohortsHelper do
  describe "#format_year_group" do
    subject(:formatted_year_group) { helper.format_year_group(year_group) }

    context "when the year group is negative" do
      let(:year_group) { -1 }

      it { should eq("Nursery") }
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
end
