# frozen_string_literal: true

require "rails_helper"

describe AppVaccinationRecordTableComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_records) }

  let(:campaign) { create(:campaign) }
  let(:vaccination_records) do
    [
      create(
        :vaccination_record,
        patient_attributes: {
          first_name: "John",
          last_name: "Smith",
          nhs_number: "9999999999",
          date_of_birth: Date.new(2000, 5, 28),
          address_postcode: "SW1A 2AA"
        },
        session_attributes: {
          date: Date.new(2020, 1, 1),
          campaign:
        }
      )
    ] + create_list(:vaccination_record, 9, session_attributes: { campaign: })
  end

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "Vaccination records"
    )
  end

  it "renders a caption" do
    expect(rendered).to have_css(
      ".nhsuk-table__caption",
      text: "10 vaccination records"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Full name")
    expect(rendered).to have_css(".nhsuk-table__header", text: "NHS number")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Date of birth")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Postcode")
    expect(rendered).to have_css(
      ".nhsuk-table__header",
      text: "Vaccinated date"
    )
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 10
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "John Smith")
    expect(rendered).to have_link("John Smith")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "999 999 9999")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "SW1A 2AA")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "28 May 2000")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1 January 2020")
  end
end
