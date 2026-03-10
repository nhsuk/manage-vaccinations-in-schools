# frozen_string_literal: true

describe Reports::AutomatedCareplusExporter do
  subject(:csv) do
    described_class.call(
      team:,
      programme:,
      academic_year:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end

  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  let(:academic_year) { AcademicYear.current }
  let(:programme) { Programme.hpv }
  let(:programmes) { [programme] }
  let(:team) do
    create(
      :team,
      careplus_staff_code: "ABCD",
      careplus_staff_type: "PQ",
      careplus_venue_code: "ABC",
      programmes:
    )
  end

  let(:headers) { CSV.parse(csv).first }
  let(:manual_headers) do
    CSV.parse(
      Reports::ManualCareplusExporter.call(
        team:,
        programme:,
        academic_year:,
        start_date: 1.month.ago.to_date,
        end_date: Date.current
      )
    ).first
  end

  it "matches the manual careplus headers except for gender and vaccine code columns" do
    expected_headers =
      manual_headers.reject do |header|
        header == "Gender" || header.start_with?("Vaccine Code ")
      end

    expect(headers).to eq(expected_headers)
  end
end
