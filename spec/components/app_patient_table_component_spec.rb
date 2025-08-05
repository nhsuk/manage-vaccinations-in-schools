# frozen_string_literal: true

describe AppPatientTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patients, current_user:, count:) }

  let(:patients) do
    [
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        nhs_number: "9991000003",
        date_of_birth: Date.new(2000, 5, 28),
        address_postcode: "SW1A 1AA"
      ),
      create(
        :patient,
        :restricted,
        given_name: "Jenny",
        family_name: "Smith",
        nhs_number: "9991000011",
        date_of_birth: Date.new(2000, 5, 28),
        address_postcode: "SW1B 1AA"
      )
    ] + create_list(:patient, 8)
  end

  let(:current_user) { create(:nurse) }

  let(:count) { 10 }

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "10 children"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(
      ".nhsuk-table__header",
      text: "Name and NHS number"
    )
    expect(rendered).to have_css(".nhsuk-table__header", text: "Postcode")
    expect(rendered).to have_css(".nhsuk-table__header", text: "School")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Date of birth")
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 10
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "SMITH, John")
    expect(rendered).to have_css(
      ".nhsuk-table__cell .nhsuk-u-nowrap",
      text: "999 100 0003"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "28 May 2000")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "SW1A 1AA")
  end

  it "doesn't show postcode of restricted patients" do
    expect(rendered).not_to have_text("SW1B 1AA")
  end

  context "with a patient not in the cohort" do
    it "doesn't render a link" do
      expect(rendered).not_to have_link("SMITH, John")
      expect(rendered).to have_content("Child has moved out of the area")
    end
  end

  context "with a patient in the cohort" do
    let(:team) { current_user.selected_team }
    let(:session) { create(:session, team:) }

    before { create(:patient_session, patient: patients.first, session:) }

    it "renders links" do
      expect(rendered).to have_link("SMITH, John")
    end
  end
end
