# frozen_string_literal: true

describe Reports::ManualCareplusExporter do
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
  let(:team) { create(:team, programmes:) }
  let(:location) { create(:school) }
  let(:session) { create(:session, team:, programmes:, location:) }
  let(:parsed_csv) { CSV.parse(csv) }
  let(:headers) { parsed_csv.first }
  let(:data_rows) { parsed_csv[1..] }

  it "includes the Gender header" do
    expect(headers).to include("Gender")
  end

  it "includes the Vaccine Code headers" do
    (1..5).each { |i| expect(headers).to include("Vaccine Code #{i}") }
  end

  context "gender mapping" do
    {
      female: "F",
      male: "M",
      not_known: "U",
      not_specified: "I"
    }.each do |gender, expected_code|
      context "when the patient gender is #{gender}" do
        it "maps gender to #{expected_code}" do
          patient =
            create(
              :patient,
              :consent_given_triage_not_needed,
              programmes:,
              session:,
              gender_code: gender
            )
          create(
            :vaccination_record,
            programme:,
            patient:,
            session:,
            performed_at: 2.weeks.ago
          )

          gender_index = headers.index("Gender")
          expect(data_rows.first[gender_index]).to eq(expected_code)
        end
      end
    end
  end
end
