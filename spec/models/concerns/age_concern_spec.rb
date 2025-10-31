# frozen_string_literal: true

describe AgeConcern do
  let(:dummy_class) do
    Class.new do
      include AgeConcern

      attr_reader :date_of_birth

      def initialize(date_of_birth:)
        @date_of_birth = date_of_birth
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Dummy")
      end

      def [](attr)
        send(attr)
      end
    end
  end

  describe "#age_months" do
    subject { dummy_class.new(date_of_birth:).age_months(now:) }

    context "when date_of_birth is 1 year minus 1 day in the past" do
      let(:date_of_birth) { Date.new(2009, 2, 2) }
      let(:now) { Date.new(2010, 2, 1) }

      it { should eq 11 }
    end

    context "when date_of_birth is on a leap day" do
      let(:date_of_birth) { Date.new(2008, 2, 29) }

      context "and today is 365 days later but same month" do
        let(:now) { Date.new(2009, 2, 28) }

        it { should eq 11 }
      end

      context "and today is a year later" do
        let(:now) { Date.new(2009, 3, 1) }

        it { should eq 12 }
      end
    end

    context "when date_of_birth is 10 years and one month in the past" do
      let(:date_of_birth) { Date.new(2009, 12, 1) }
      let(:now) { Date.new(2020, 1, 1) }

      it { should eq 121 }

      context "today is a leap day" do
        let(:date_of_birth) { Date.new(2010, 1, 31) }
        let(:now) { Date.new(2020, 2, 29) }

        it { should eq 120 }
      end
    end

    context "when date_of_birth is exactly 10 years in the past" do
      let(:date_of_birth) { Date.new(2010, 1, 1) }
      let(:now) { Date.new(2020, 1, 1) }

      it { should eq 120 }

      context "today is a leap day" do
        let(:date_of_birth) { Date.new(2010, 2, 28) }
        let(:now) { Date.new(2020, 2, 29) }

        it { should eq 120 }
      end
    end

    context "when date_of_birth is 10 years less a day in the past" do
      let(:date_of_birth) { Date.new(2010, 2, 1) }
      let(:now) { Date.new(2020, 1, 1) }

      it { should eq 119 }

      context "today is a leap day" do
        let(:date_of_birth) { Date.new(2010, 3, 31) }
        let(:now) { Date.new(2020, 2, 29) }

        it { should eq 118 }
      end
    end
  end

  describe "#age_years" do
    subject { dummy_class.new(date_of_birth:).age_years }

    context "when date_of_birth is 10 years and one day in the past" do
      let(:date_of_birth) { (10.years + 1.day).ago.to_date }

      it { should eq 10 }

      context "today is a leap day" do
        around { |example| travel_to(Date.new(2020, 2, 29)) { example.run } }

        it { should eq 10 }
      end
    end

    context "when date_of_birth is exactly 10 years in the past" do
      let(:date_of_birth) { 10.years.ago.to_date }

      it { should eq 10 }

      context "today is a leap day" do
        around { |example| travel_to(Date.new(2020, 2, 29)) { example.run } }

        it { should eq 10 }
      end
    end

    context "when date_of_birth is 10 years less a day in the past" do
      let(:date_of_birth) { (10.years - 1.day).ago.to_date }

      it { should eq 9 }

      context "today is a leap day" do
        around { |example| travel_to(Date.new(2020, 2, 29)) { example.run } }

        it { should eq 9 }
      end
    end
  end
end
