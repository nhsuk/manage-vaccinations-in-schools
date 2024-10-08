# frozen_string_literal: true

describe AppImportsTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(team:, programme:) }

  let(:team) { create(:team) }
  let(:programme) { create(:programme) }

  before do
    cohort_imports =
      [
        create(
          :cohort_import,
          :recorded,
          team:,
          programme:,
          created_at: Date.new(2020, 1, 1),
          uploaded_by:
            create(:user, given_name: "Jennifer", family_name: "Smith")
        )
      ] + create_list(:cohort_import, 4, :recorded, team:, programme:)

    cohort_imports.each do |cohort_import|
      create(:patient, cohort_imports: [cohort_import])
    end

    immunisation_imports =
      [
        create(
          :immunisation_import,
          :recorded,
          team:,
          programme:,
          created_at: Date.new(2020, 1, 1),
          uploaded_by: create(:user, given_name: "John", family_name: "Smith")
        )
      ] + create_list(:immunisation_import, 4, :recorded, team:, programme:)

    immunisation_imports.each do |immunisation_import|
      create(
        :vaccination_record,
        programme:,
        immunisation_imports: [immunisation_import]
      )
    end
  end

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "10 completed imports"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Imported on")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Imported by")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Import type")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Records")
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 10
    )
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: "1 January 2020 at 12:00am"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "Child record")
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: "Vaccination record"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "John Smith")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "Jennifer Smith")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1")
  end
end
