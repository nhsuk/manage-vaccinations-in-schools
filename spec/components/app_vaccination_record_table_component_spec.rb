# frozen_string_literal: true

describe AppVaccinationRecordTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(vaccination_records, current_user:, count: 10)
  end

  let(:programme) { CachedProgramme.sample }
  let(:vaccination_records) do
    [
      create(
        :vaccination_record,
        programme:,
        performed_at: Time.zone.local(2020, 9, 1),
        patient:
          create(
            :patient,
            given_name: "John",
            family_name: "Smith",
            nhs_number: "9999999999",
            date_of_birth: Date.new(2000, 5, 28),
            address_postcode: "SW1A 2AA"
          ),
        session:
          create(:session, programmes: [programme], date: Date.new(2020, 9, 1))
      )
    ] + create_list(:vaccination_record, 4, programme:) +
      create_list(:vaccination_record, 5, :not_administered, programme:)
  end

  let(:current_user) { create(:nurse) }

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "10 vaccination records"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Full name")
    expect(rendered).to have_css(".nhsuk-table__header", text: "NHS number")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Date of birth")
    expect(rendered).to have_css(
      ".nhsuk-table__header",
      text: "Vaccination date"
    )
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 10
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "SMITH, John")
    expect(rendered).to have_link("SMITH, John")
    expect(rendered).to have_css(
      ".nhsuk-table__cell .nhsuk-u-nowrap",
      text: "999 999 9999"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "28 May 2000")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1 September 2020")
  end

  context "with a vaccination record not performed by the team" do
    before do
      vaccination_records.first.patient.patient_locations.destroy_all
      vaccination_records.first.update!(
        session: nil,
        source: "historical_upload",
        location: nil,
        location_name: "Unknown",
        performed_ods_code: nil
      )
    end

    it { should_not have_link("SMITH, John") }
  end
end
