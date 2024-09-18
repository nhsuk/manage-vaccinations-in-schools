# frozen_string_literal: true

describe AppPatientTableComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patients, programme:) }

  let(:programme) { create(:programme, academic_year: 2020) }
  let(:session) { create(:session, programme:) }
  let(:patients) do
    [
      create(
        :patient,
        first_name: "John",
        last_name: "Smith",
        nhs_number: "9999999999",
        date_of_birth: Date.new(2000, 5, 28),
        session:
      )
    ] + create_list(:patient, 9, session:)
  end

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "10 children in this programme’s cohort"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Full name")
    expect(rendered).to have_css(".nhsuk-table__header", text: "NHS number")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Date of birth")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Outcome")
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
    expect(rendered).to have_css(".nhsuk-table__cell", text: "No outcome yet")
  end
end
