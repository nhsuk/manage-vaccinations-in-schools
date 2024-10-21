# frozen_string_literal: true

describe AppImportFormatDetailsComponent, type: :component do
  let(:programme) { create(:programme, :hpv) }

  it "renders the correct summary text for ClassImport" do
    import = ClassImport.new
    render_inline(described_class.new(import:))
    expect(page).to have_content("How to format your CSV for class lists")
  end

  it "renders the correct summary text for CohortImport" do
    import = CohortImport.new
    render_inline(described_class.new(import:))
    expect(page).to have_content("How to format your CSV for child records")
  end

  it "renders the correct summary text for ImmunisationImport" do
    import = ImmunisationImport.new(programme:)
    render_inline(described_class.new(import:, programme:))
    expect(page).to have_content(
      "How to format your CSV for vaccination records"
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
    import = ClassImport.new
    render_inline(described_class.new(import:))
    expect(page).to have_content("CHILD_FIRST_NAME")
    expect(page).to have_content("CHILD_LAST_NAME")
    expect(page).to have_content("CHILD_DATE_OF_BIRTH")
    expect(page).to have_content("CHILD_POSTCODE")
    expect(page).to have_content("CHILD_REGISTRATION")
    expect(page).to have_content("PARENT_1_EMAIL")
    expect(page).to have_content("PARENT_1_PHONE")
  end

  it "renders the correct columns for CohortImport" do
    import = CohortImport.new
    render_inline(described_class.new(import:))
    expect(page).to have_content("CHILD_FIRST_NAME")
    expect(page).to have_content("CHILD_LAST_NAME")
    expect(page).to have_content("CHILD_DATE_OF_BIRTH")
    expect(page).to have_content("CHILD_SCHOOL_URN")
    expect(page).to have_content("CHILD_POSTCODE")
    expect(page).to have_content("CHILD_REGISTRATION")
    expect(page).to have_content("PARENT_1_NAME")
    expect(page).to have_content("PARENT_2_NAME")
  end

  it "renders the correct columns for ImmunisationImport" do
    import = ImmunisationImport.new(programme:)
    render_inline(described_class.new(import:, programme:))
    expect(page).to have_content("ORGANISATION_CODE")
    expect(page).to have_content("SCHOOL_URN")
    expect(page).to have_content("PERSON_FORENAME")
    expect(page).to have_content("PERSON_SURNAME")
    expect(page).to have_content("DATE_OF_VACCINATION")
    expect(page).to have_content("VACCINE_GIVEN")
  end

  it "includes HPV-specific columns for HPV programmes" do
    import = ImmunisationImport.new(programme:)
    render_inline(described_class.new(import:, programme:))
    expect(page).to have_content("DOSE_SEQUENCE")
    expect(page).to have_content("CARE_SETTING")
  end

  it "does not include HPV-specific columns for non-HPV programmes" do
    programme = create(:programme, :flu)
    import = ImmunisationImport.new(programme:)
    render_inline(described_class.new(import:, programme:))
    expect(page).not_to have_content("DOSE_SEQUENCE")
    expect(page).not_to have_content("CARE_SETTING")
  end
end
