# frozen_string_literal: true

describe AppVaccinationRecordTableComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_records) }

  let(:programme) { create(:programme, :active, academic_year: 2020) }
  let(:vaccination_records) do
    [
      create(
        :vaccination_record,
        administered_at: Time.zone.local(2020, 9, 1),
        patient:
          create(
            :patient,
            first_name: "John",
            last_name: "Smith",
            nhs_number: "9999999999",
            date_of_birth: Date.new(2000, 5, 28),
            address_postcode: "SW1A 2AA"
          ),
        session: create(:session, programme:, date: Date.new(2020, 9, 1))
      )
    ] + create_list(:vaccination_record, 4, programme:) +
      create_list(:vaccination_record, 5, :not_administered, programme:)
  end

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "10 vaccination records"
    )
  end

  context "with new records" do
    let(:component) do
      described_class.new(vaccination_records, new_records: true)
    end

    it "renders a heading tab with the word new" do
      expect(rendered).to have_css(
        ".nhsuk-table__heading-tab",
        text: "10 new vaccination records"
      )
    end
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
    expect(rendered).to have_css(".nhsuk-table__cell", text: "John Smith")
    expect(rendered).to have_link("John Smith")
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: "999\u00A0\u200D999\u00A0\u200D9999"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "28 May 2000")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1 September 2020")
  end
end
