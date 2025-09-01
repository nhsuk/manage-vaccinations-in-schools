# frozen_string_literal: true

describe AppImportPDSUnmatchedSummaryComponent, type: :component do
  let(:import) { create(:cohort_import) }

  let(:rendered) { render_inline(component) }

  let(:component) { described_class.new(changesets: changesets) }

  let(:changesets) { [changeset] }

  let(:changeset) do
    create(
      :patient_changeset,
      pending_changes: {
        child: {
          "given_name" => "Alice",
          "family_name" => "Smith",
          "date_of_birth" => Date.new(2010, 5, 15),
          "address_postcode" => "AB1 2CD"
        }
      },
      import:
    )
  end

  it "renders the table headers" do
    expect(rendered).to have_content("First name")
    expect(rendered).to have_content("Last name")
    expect(rendered).to have_content("Date of birth")
    expect(rendered).to have_content("Postcode")
  end

  it "renders the record details" do
    expect(rendered).to have_content("Alice")
    expect(rendered).to have_content("Smith")
    expect(rendered).to have_content("15 May 2010")
    expect(rendered).to have_content("AB1 2CD")
  end

  context "with multiple records" do
    let(:changesets) { [changeset, other_changeset] }

    let(:other_changeset) do
      create(
        :patient_changeset,
        pending_changes: {
          child: {
            "given_name" => "Bob",
            "family_name" => "Jones",
            "date_of_birth" => Date.new(2011, 8, 20),
            "address_postcode" => "ZZ9 9ZZ"
          }
        },
        import:
      )
    end

    it "renders all records" do
      expect(rendered).to have_content("Alice")
      expect(rendered).to have_content("Bob")
      expect(rendered).to have_content("Jones")
      expect(rendered).to have_content("20 August 2011")
      expect(rendered).to have_content("ZZ9 9ZZ")
    end
  end

  context "when values are blank" do
    let(:changeset) do
      create(:patient_changeset, pending_changes: { child: {} }, import:)
    end

    it "renders empty cells" do
      expect(rendered).to have_css("table")
    end
  end
end
