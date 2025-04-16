# frozen_string_literal: true

describe AppVaccinationRecordTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(vaccination_records, current_user:, count:)
  end

  let(:programme) { create(:programme) }
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

  let(:count) { 10 }

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
      ".nhsuk-table__cell",
      text: "999\u00A0\u200D999\u00A0\u200D9999"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "28 May 2000")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1 September 2020")
  end

  context "with a vaccination record not performed by the organisation" do
    before { vaccination_records.first.patient.update!(organisation: nil) }

    it "doesn't render a link" do
      expect(rendered).not_to have_link("SMITH, John")
    end
  end
end
