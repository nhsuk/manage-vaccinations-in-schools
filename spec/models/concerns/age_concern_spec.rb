# frozen_string_literal: true

require "rails_helper"

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

  describe ".age" do
    subject { dummy_class.new(date_of_birth:).age }

    context "when date_of_birth is 10 years and one day in the past" do
      let(:date_of_birth) { (10.years + 1.day).ago.to_date }

      it { should eq 10 }

      context "today is a leap day" do
        before { Timecop.freeze(Date.new(2020, 2, 29)) }
        after { Timecop.return }

        it { should eq 10 }
      end
    end

    context "when date_of_birth is exactly 10 years in the past" do
      let(:date_of_birth) { 10.years.ago.to_date }

      it { should eq 10 }

      context "today is a leap day" do
        before { Timecop.freeze(Date.new(2020, 2, 29)) }
        after { Timecop.return }

        it { should eq 10 }
      end
    end

    context "when date_of_birth is 10 years less a day in the past" do
      let(:date_of_birth) { (10.years - 1.day).ago.to_date }

      it { should eq 9 }

      context "today is a leap day" do
        before { Timecop.freeze(Date.new(2020, 2, 29)) }
        after { Timecop.return }

        it { should eq 9 }
      end
    end
  end
end
