# frozen_string_literal: true

describe AcademicYearsHelper do
  describe "#format_academic_year" do
    subject { format_academic_year(2025) }

    it { should eq("2025 to 2026") }
  end
end
