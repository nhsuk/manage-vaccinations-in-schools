# frozen_string_literal: true

describe "WithinAcademicYear sets the current date" do
  subject(:current_date) { Date.current }

  let(:current_academic_year) { AcademicYear.current }
  let(:next_academic_year) { current_academic_year + 1 }
  # We define the next one to try to make clear even though we are testing a
  # date in the "next" year, our intention isn't to place a date in the next
  # academic year. i.e we'll be defining a date before the end of the academic
  # year.
  let(:preparatory_period_year) { current_academic_year + 1 }

  prepend_before { travel_to(test_date) }

  describe "with within_academic_year not set" do
    context "within the academic year" do
      let(:test_date) { Date.new(current_academic_year, 8, 14) }

      it { should eq test_date }
    end

    context "during the preparatory period" do
      let(:test_date) { Date.new(preparatory_period_year, 8, 14) }

      it { should eq test_date }
    end
  end

  describe "when within_academic_year is false", within_academic_year: false do
    context "within the academic year" do
      let(:test_date) { Date.new(current_academic_year, 8, 14) }

      it { should eq test_date }
    end

    context "during the preparatory period" do
      let(:test_date) { Date.new(preparatory_period_year, 8, 14) }

      it { should eq test_date }
    end
  end

  describe "when within_academic_year is true", :within_academic_year do
    context "within the academic year" do
      let(:test_date) { Date.new(current_academic_year, 9, 14) }

      it { should eq Date.new(current_academic_year, 9, 14) }
    end

    context "during preparatory period" do
      let(:test_date) { Date.new(preparatory_period_year, 8, 14) }

      it { should eq Date.new(next_academic_year, 9, 1) }
    end
  end

  describe "using from_start to ensure back-dated dates are handled correctly",
           within_academic_year: {
             from_start: 21.days
           } do
    context "when too close to the beginning of the academic year" do
      let(:test_date) { Date.new(current_academic_year, 9, 14) }

      it { should eq Date.new(current_academic_year, 9, 22) }
    end

    context "within the academic year" do
      let(:test_date) { Date.new(current_academic_year, 10, 1) }

      it { should eq Date.new(current_academic_year, 10, 1) }
    end

    context "during the preparatory period" do
      let(:test_date) { Date.new(preparatory_period_year, 8, 14) }

      it { should eq Date.new(next_academic_year, 9, 22) }
    end
  end
end
