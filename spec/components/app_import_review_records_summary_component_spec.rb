# frozen_string_literal: true

describe AppImportReviewRecordsSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(changesets:) }
  let(:team) { create(:team) }
  let(:import) { create(:cohort_import, team:) }
  let(:changesets) { [] }

  describe "table structure" do
    let(:changesets) { [create(:patient_changeset, import:, row_number: 1)] }

    it "renders a table" do
      expect(rendered).to have_css("table.nhsuk-table-responsive")
    end

    it "renders table headers" do
      expect(rendered).to have_css("th", text: "CSV file row")
      expect(rendered).to have_css("th", text: "Name and NHS number")
      expect(rendered).to have_css("th", text: "Date of birth")
      expect(rendered).to have_css("th", text: "Postcode")
      expect(rendered).to have_css("th", text: "Year group")
    end
  end

  describe "with changesets" do
    let(:changesets) { [create(:patient_changeset, import:, row_number: 5)] }

    before do
      changesets.sole.data["upload"]["child"] = {
        "given_name" => "John",
        "family_name" => "Dover",
        "date_of_birth" => "2010-01-01",
        "address_postcode" => "SW1A 1AA",
        "nhs_number" => "9435792103",
        "birth_academic_year" => 2009
      }
      changesets.sole.save!
    end

    it "displays CSV file row number" do
      expect(rendered).to have_css("td", text: "7")
    end

    it "displays patient name" do
      expect(rendered).to have_css("td", text: /DOVER, John/i)
    end

    it "displays NHS number" do
      expect(rendered).to have_css(
        "td .nhsuk-u-secondary-text-colour",
        text: "943 579 2103"
      )
    end

    it "displays date of birth" do
      expect(rendered).to have_css("td", text: "1 January 2010")
    end

    it "displays postcode" do
      expect(rendered).to have_css("td", text: "SW1A 1AA")
    end

    it "displays year group" do
      expect(rendered).to have_css("td", text: /Year \d+/)
    end
  end

  describe "with no NHS number" do
    let(:changesets) { [create(:patient_changeset, import:, row_number: 1)] }

    before do
      changesets.first.data["upload"]["child"]["nhs_number"] = nil
      changesets.first.save!
    end

    it "displays 'Not provided' for NHS number" do
      expect(rendered).to have_css("td", text: "Not provided")
    end
  end

  describe "sorting changesets" do
    let(:changesets) do
      [
        create(:patient_changeset, import:, row_number: 3),
        create(:patient_changeset, import:, row_number: 1),
        create(:patient_changeset, import:, row_number: 2)
      ]
    end

    it "sorts changesets by row number" do
      rows = rendered.css("tbody .nhsuk-table__row")

      # Row numbers are incremented by 2 (to account for header rows in CSV)
      expect(rows[0].text).to include("3") # row_number 1 + 2
      expect(rows[1].text).to include("4") # row_number 2 + 2
      expect(rows[2].text).to include("5") # row_number 3 + 2
    end
  end

  describe "with multiple changesets" do
    let(:changesets) do
      [
        create(:patient_changeset, import:, row_number: 1),
        create(:patient_changeset, import:, row_number: 2)
      ]
    end

    before do
      changesets[0].data["upload"]["child"].merge!(
        "given_name" => "Alice",
        "family_name" => "Smith",
        "nhs_number" => "9435792103"
      )
      changesets[1].data["upload"]["child"].merge!(
        "given_name" => "Bob",
        "family_name" => "Jones",
        "nhs_number" => "9435740820"
      )
      changesets.each(&:save!)
    end

    it "renders all changesets" do
      rows = rendered.css("tbody .nhsuk-table__row")
      expect(rows.size).to eq(2)
    end

    it "displays correct names for each changeset" do
      expect(rendered).to have_css("td", text: /SMITH, Alice/i)
      expect(rendered).to have_css("td", text: /JONES, Bob/i)
    end

    it "displays correct NHS numbers for each changeset" do
      expect(rendered).to have_css("td", text: "943 579 2103")
      expect(rendered).to have_css("td", text: "943 574 0820")
    end
  end

  describe "with empty changesets" do
    let(:changesets) { [] }

    it "renders empty table body" do
      expect(rendered).to have_css("tbody")
      expect(rendered).not_to have_css("tbody tr")
    end
  end

  describe "with different year groups" do
    let(:changesets) do
      [
        create(:patient_changeset, import:, row_number: 1),
        create(:patient_changeset, import:, row_number: 2)
      ]
    end

    before do
      changesets[0].data["upload"]["child"]["birth_academic_year"] = 2013
      changesets[1].data["upload"]["child"]["birth_academic_year"] = 2009
      changesets.each(&:save!)
    end

    it "displays different year groups correctly" do
      expect(rendered).to have_css("td", text: /Year 7/i)
      expect(rendered).to have_css("td", text: /Year 11/i)
    end
  end

  describe "with missing postcode" do
    let(:changesets) { [create(:patient_changeset, import:, row_number: 1)] }

    before do
      changesets.first.data["upload"]["child"]["address_postcode"] = nil
      changesets.first.save!
    end

    it "renders empty postcode cell" do
      postcode_cell = rendered.css("tbody tr td")[3]
      expect(postcode_cell.text).to match(/Postcode\s*$/)
    end
  end

  describe "formatting" do
    let(:changesets) { [create(:patient_changeset, import:, row_number: 10)] }

    before do
      changesets.first.data["upload"]["child"].merge!(
        "given_name" => "mary",
        "family_name" => "o'brien",
        "date_of_birth" => "2015-03-15",
        "address_postcode" => "sw1a 2aa",
        "nhs_number" => "9435797881"
      )
      changesets.first.save!
    end

    it "formats name correctly (capitalized)" do
      expect(rendered).to have_css("td", text: /O'BRIEN, Mary/i)
    end

    it "formats NHS number with spaces" do
      expect(rendered).to have_css("td", text: "943 579 7881")
    end

    it "formats date of birth as long format" do
      expect(rendered).to have_css("td", text: "15 March 2015")
    end

    it "formats postcode in uppercase" do
      expect(rendered).to have_css("td", text: /SW1A 2AA/i)
    end
  end
end
