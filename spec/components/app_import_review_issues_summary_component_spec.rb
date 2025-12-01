# frozen_string_literal: true

describe AppImportReviewIssuesSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(import:, records:, review_screen:) }

  let(:team) { create(:team) }
  let(:import) { create(:cohort_import, team:) }
  let(:review_screen) { true }
  let(:records) { [] }

  describe "table structure" do
    let(:patient) { create(:patient, given_name: "John", family_name: "Dover") }
    let(:records) do
      [
        create(
          :patient_changeset,
          :import_issue,
          import:,
          patient:,
          row_number: 1
        )
      ]
    end

    it "renders a table" do
      expect(rendered).to have_css("table.nhsuk-table-responsive")
    end

    context "on review screen" do
      let(:review_screen) { true }

      it "shows CSV file row column" do
        expect(rendered).to have_css("th", text: "CSV file row")
      end

      it "shows name and NHS number column" do
        expect(rendered).to have_css("th", text: "Name and NHS number")
      end

      it "shows issue to review column" do
        expect(rendered).to have_css("th", text: "Issue to review")
      end

      it "does not show actions column" do
        expect(rendered).not_to have_css("th", text: "Actions")
      end
    end

    context "not on review screen" do
      let(:review_screen) { false }

      it "does not show CSV file row column" do
        expect(rendered).not_to have_css("th", text: "CSV file row")
      end

      it "shows actions column" do
        expect(rendered).to have_css("th", text: "Actions")
      end
    end
  end

  describe "with changeset records" do
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Dover",
        nhs_number: "9435780156"
      )
    end
    let(:changeset) do
      create(
        :patient_changeset,
        :import_issue,
        import:,
        patient:,
        row_number: 5,
        matched_on_nhs_number: true
      )
    end
    let(:records) { [changeset] }

    before do
      changeset.data["review"] = {
        "patient" => {
          "pending_changes" => {
            "address_postcode" => "SW1A 1AA"
          }
        }
      }
      changeset.save!
    end

    it "displays the row number" do
      expect(rendered).to have_css("td", text: "7")
    end

    it "displays patient name" do
      expect(rendered).to have_css("td", text: /DOVER, John/i)
    end

    it "displays NHS number" do
      expect(rendered).to have_css("td", text: "943 578 0156")
    end

    it "displays issue text for matched on NHS number" do
      expect(rendered).to have_css(
        "td",
        text: /Matched on NHS number.*Address does not match/i
      )
    end

    context "when not matched on NHS number" do
      before { changeset.update!(matched_on_nhs_number: false) }

      it "displays generic match text" do
        expect(rendered).to have_css(
          "td",
          text: "Possible match found. Review and confirm."
        )
      end
    end

    context "with multiple pending changes" do
      before do
        changeset.data["review"]["patient"]["pending_changes"] = {
          "address_postcode" => "SW1A 1AA",
          "given_name" => "Johnny"
        }
        changeset.save!
      end

      it "displays multiple issues with plural grammar" do
        expect(rendered).to have_css(
          "td",
          text: /Matched on NHS number.*do not match/i
        )
      end
    end
  end

  describe "with patient records" do
    let(:patient) do
      create(
        :patient,
        given_name: "Jane",
        family_name: "Smith",
        nhs_number: "9435758649"
      )
    end
    let(:records) { [patient] }
    let(:review_screen) { false }

    it "displays patient name" do
      expect(rendered).to have_css("td", text: /SMITH, Jane/i)
    end

    it "displays NHS number" do
      expect(rendered).to have_css("td", text: "943 575 8649")
    end

    it "displays review link" do
      expect(rendered).to have_link(
        "Review",
        href:
          Rails.application.routes.url_helpers.imports_issue_path(
            patient,
            type: "patient"
          )
      )
    end

    it "includes visually hidden patient name in link" do
      link = rendered.css("a").find { |a| a.text.include?("Review") }
      expect(link.css(".nhsuk-u-visually-hidden").text).to include(
        "SMITH, Jane"
      )
    end
  end

  describe "with vaccination records" do
    let(:patient) { create(:patient, given_name: "Bob", family_name: "Jones") }
    let(:vaccination_record) do
      create(:vaccination_record, patient:, programme: Programme.hpv)
    end
    let(:records) { [vaccination_record] }
    let(:review_screen) { false }

    it "displays patient name" do
      expect(rendered).to have_css("td", text: /JONES, Bob/i)
    end

    it "displays issue text for vaccination records" do
      expect(rendered).to have_css(
        "td",
        text:
          "Imported record closely matches an existing record. Review and confirm."
      )
    end

    it "displays review link" do
      expect(rendered).to have_link(
        "Review",
        href:
          Rails.application.routes.url_helpers.imports_issue_path(
            vaccination_record,
            type: "vaccination-record"
          )
      )
    end
  end

  describe "sorting records" do
    let(:changeset_a) do
      create(:patient_changeset, :import_issue, import:, row_number: 3)
    end
    let(:changeset_b) do
      create(:patient_changeset, :import_issue, import:, row_number: 1)
    end
    let(:changeset_c) do
      create(:patient_changeset, :import_issue, import:, row_number: 2)
    end
    let(:records) { [changeset_a, changeset_b, changeset_c] }

    it "sorts records by row number" do
      rows = rendered.css("tbody .nhsuk-table__row")
      expect(rows[0].text).to include("3")
      expect(rows[1].text).to include("4")
      expect(rows[2].text).to include("5")
    end
  end

  describe "with no records" do
    let(:records) { [] }

    it "renders empty table body" do
      expect(rendered).to have_css("tbody")
      expect(rendered).not_to have_css("tbody tr")
    end
  end
end
