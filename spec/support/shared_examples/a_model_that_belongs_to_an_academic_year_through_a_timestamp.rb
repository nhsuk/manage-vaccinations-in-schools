# frozen_string_literal: true

shared_examples_for "a model that belongs to an academic year through a timestamp" do |attribute|
  it_behaves_like "a model that belongs to an academic year"
  describe "#academic_year" do
    let(:examples) do
      {
        Date.new(2020, 9, 1) => 2020,
        Date.new(2021, 8, 31) => 2020,
        Date.new(2021, 9, 1) => 2021,
        Date.new(2022, 8, 31) => 2021
      }
    end

    examples.each do |date, academic_year|
      context "with #{date}" do
        before { subject[attribute] = date }

        it { expect(subject.academic_year).to eq(academic_year) }
      end
    end
  end
end
