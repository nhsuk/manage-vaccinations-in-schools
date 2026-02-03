# frozen_string_literal: true

describe BatchForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it { should validate_length_of(:number).is_at_least(2).is_at_most(100) }
    it { should validate_presence_of(:number) }

    it { should validate_presence_of(:expiry) }

    it do
      travel_to(Date.new(2024, 9, 1)) do
        expect(form).to validate_comparison_of(:expiry).is_greater_than(
          Date.new(2024, 9, 1)
        )
        expect(form).to validate_comparison_of(:expiry).is_less_than(
          Date.new(2039, 9, 1)
        )
      end
    end
  end
end
