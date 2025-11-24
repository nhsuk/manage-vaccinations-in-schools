# frozen_string_literal: true

describe AppImportFormatDetailsComponent do
  let(:programme) { Programme.hpv }
  let(:team) { create(:team, programmes: [programme]) }

  it "renders the correct summary text for ClassImport" do
    import = ClassImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content(
      "How to format your Mavis CSV file for class lists"
    )
  end

  it "renders the correct summary text for CohortImport" do
    import = CohortImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content(
      "How to format your Mavis CSV file for child records"
    )
  end

  it "renders the correct summary text for ImmunisationImport" do
    import = ImmunisationImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content(
      "How to format your Mavis CSV file for vaccination records"
    )
  end

  it "raises an error for unsupported import types" do
    import = Object.new
    expect { render_inline(described_class.new(import:)) }.to raise_error(
      ArgumentError,
      "Unsupported import type: Object"
    )
  end

  it "renders the correct columns for ClassImport" do
    import = ClassImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content("CHILD_FIRST_NAME")
    expect(page).to have_content("CHILD_LAST_NAME")
    expect(page).to have_content("CHILD_DATE_OF_BIRTH")
    expect(page).to have_content("CHILD_YEAR_GROUP")
    expect(page).to have_content("CHILD_REGISTRATION")
    expect(page).to have_content("CHILD_POSTCODE")
    expect(page).to have_content("PARENT_1_EMAIL")
    expect(page).to have_content("PARENT_1_PHONE")
  end

  it "renders the correct columns for CohortImport" do
    import = CohortImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content("CHILD_FIRST_NAME")
    expect(page).to have_content("CHILD_LAST_NAME")
    expect(page).to have_content("CHILD_DATE_OF_BIRTH")
    expect(page).to have_content("CHILD_YEAR_GROUP")
    expect(page).to have_content("CHILD_REGISTRATION")
    expect(page).to have_content("CHILD_POSTCODE")
    expect(page).to have_content("CHILD_SCHOOL_URN")
    expect(page).to have_content("PARENT_1_NAME")
    expect(page).to have_content("PARENT_2_NAME")
  end

  it "renders the correct columns for ImmunisationImport" do
    import = ImmunisationImport.new(team:)
    render_inline(described_class.new(import:))
    expect(page).to have_content("ORGANISATION_CODE")
    expect(page).to have_content("SCHOOL_URN")
    expect(page).to have_content("PERSON_FORENAME")
    expect(page).to have_content("PERSON_SURNAME")
    expect(page).to have_content("DATE_OF_VACCINATION")
    expect(page).to have_content("VACCINE_GIVEN")
    expect(page).to have_content("CARE_SETTING")
    expect(page).to have_content("CLINIC_NAME")
  end
end
