# frozen_string_literal: true

describe AppImportsTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(team:, uploaded_files:) }

  let(:programmes) { [Programme.sample] }
  let(:team) { create(:team, programmes:) }
  let(:school) { create(:school, team:, name: "Test School") }
  let(:session) { create(:session, programmes:, location: school) }
  let(:uploaded_files) { false }

  before do
    cohort_imports =
      [
        create(
          :cohort_import,
          :processed,
          team:,
          created_at: Date.new(2020, 1, 1),
          uploaded_by:
            create(:user, given_name: "Jennifer", family_name: "Smith")
        )
      ] + create_list(:cohort_import, 4, :processed, team:)

    cohort_imports.each do |cohort_import|
      create(:patient, cohort_imports: [cohort_import])
    end

    immunisation_imports =
      [
        create(
          :immunisation_import,
          :processed,
          team:,
          created_at: Date.new(2020, 1, 1),
          uploaded_by: create(:user, given_name: "John", family_name: "Smith")
        )
      ] + create_list(:immunisation_import, 4, :processed, team:)

    immunisation_imports.each do |immunisation_import|
      create(
        :vaccination_record,
        team:,
        programme: programmes.first,
        immunisation_imports: [immunisation_import]
      )
    end

    create(
      :class_import,
      :processed,
      team:,
      created_at: Date.new(2020, 1, 1),
      uploaded_by: create(:user, given_name: "Jack", family_name: "Smith"),
      session:
    )
  end

  it "renders a heading tab" do
    expect(rendered).to have_css(
      ".nhsuk-table__heading-tab",
      text: "11 imports"
    )
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Imported on")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Type")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Status")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Records")
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 11
    )
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: "1 January 2020 at 12:00am"
    )
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: CohortImport.first.csv_filename
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "Child record")
    expect(rendered).to have_css(
      ".nhsuk-table__cell",
      text: "Vaccination record"
    )
    expect(rendered).to have_css(".nhsuk-table__cell", text: "Class list")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "Completed")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "1")
    expect(rendered).to have_content("Test School")
  end

  context "when uploaded_files is false" do
    let(:uploaded_files) { true }

    before do
      CohortImport.destroy_all
      ImmunisationImport.destroy_all
      ClassImport.destroy_all
      create(:cohort_import, status: "pending_import", team:)
    end

    it "does not show the Records column header" do
      rendered =
        render_inline(described_class.new(team:, uploaded_files: false))
      expect(rendered).not_to have_css(".nhsuk-table__header", text: "Records")
    end

    it "does not show record counts" do
      expect(rendered).to have_css(
        ".nhsuk-table__body .nhsuk-table__row",
        count: 1
      )
      expect(rendered).not_to have_css(".nhsuk-table__cell", text: /^\d+$/)
    end
  end
end
