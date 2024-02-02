require "rails_helper"

RSpec.describe Patient do
  describe "#year_group" do
    before { Timecop.freeze(date) }
    after { Timecop.return }

    let(:patient) { Patient.new(date_of_birth: dob) }

    subject { patient.year_group }

    context "child born BEFORE 1 Sep 2016, date is BEFORE 1 Sep 2024" do
      let(:dob) { Date.new(2016, 8, 31) }
      let(:date) { Date.new(2024, 8, 31) }

      it { should eq 3 }
    end

    context "child born BEFORE 1 Sep 2016, date is AFTER 1 Sep 2024" do
      let(:dob) { Date.new(2016, 8, 31) }
      let(:date) { Date.new(2024, 9, 1) }

      it { should eq 4 }
    end

    context "child born AFTER 1 Sep 2016, date is BEFORE 1 Sep 2024" do
      let(:dob) { Date.new(2016, 9, 1) }
      let(:date) { Date.new(2024, 8, 31) }

      it { should eq 2 }
    end

    context "child born AFTER 1 Sep 2016, date is AFTER 1 Sep 2024" do
      let(:dob) { Date.new(2016, 9, 1) }
      let(:date) { Date.new(2024, 9, 1) }

      it { should eq 3 }
    end
  end
end
