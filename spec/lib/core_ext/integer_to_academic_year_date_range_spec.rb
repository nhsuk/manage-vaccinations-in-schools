# frozen_string_literal: true

describe Integer do
  describe "#to_academic_year_date_range" do
    it "converts the academic year to a date range" do
      expect(2025.to_academic_year_date_range).to eq(
        Date.new(2025, 9, 1)..Date.new(2026, 8, 31)
      )
    end
  end
end
