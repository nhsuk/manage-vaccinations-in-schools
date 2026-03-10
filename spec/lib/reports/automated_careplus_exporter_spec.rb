# frozen_string_literal: true

describe Reports::AutomatedCareplusExporter do
  subject(:csv) do
    described_class.call(
      team:,
      academic_year:,
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    )
  end

  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  let(:academic_year) { AcademicYear.current }
  let(:programmes) { Programme.all }
  let(:team) { create(:team, programmes:) }
  let(:location) { create(:school) }
  let(:session) { create(:session, team:, programmes:, location:) }

  let(:parsed_csv) { CSV.parse(csv) }
  let(:headers) { parsed_csv.first }

  it "does not include the Gender header" do
    expect(headers).not_to include("Gender")
  end

  it "does not include Vaccine Code headers" do
    expect(headers.none? { |h| h.start_with?("Vaccine Code ") }).to be true
  end

  it "includes patients vaccinated under all programme types" do
    patients =
      programmes.map do |programme|
        patient =
          create(
            :patient,
            :consent_given_triage_not_needed,
            programmes: [programme],
            session:
          )
        vaccine =
          (
            if programme.flu?
              programme.vaccines.injection.sample
            else
              programme.vaccines.first
            end
          )
        create(
          :vaccination_record,
          programme:,
          vaccine:,
          delivery_method: :intramuscular,
          patient:,
          session:,
          performed_at: 2.weeks.ago
        )
        patient
      end

    nhs_number_index = parsed_csv.first.index("NHS Number")
    exported_nhs_numbers = parsed_csv[1..].map { |row| row[nhs_number_index] }

    patients.each do |patient|
      expect(exported_nhs_numbers).to include(patient.nhs_number)
    end
  end
end
