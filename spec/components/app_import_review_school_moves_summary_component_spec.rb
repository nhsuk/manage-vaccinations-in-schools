# frozen_string_literal: true

describe AppImportReviewSchoolMovesSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(records:, review_screen:) }
  let(:academic_year) { AcademicYear.current }
  let(:team) { create(:team) }

  describe "with changesets (review_screen: true)" do
    let(:review_screen) { true }
    let(:import) { create(:cohort_import, team:) }

    describe "table structure" do
      let(:school) { create(:school, team:, name: "Test School") }
      let(:patient) { create(:patient, school:) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: 1)]
      end

      it "renders a table with correct headers" do
        expect(rendered).to have_css("table.nhsuk-table-responsive")
        expect(rendered).to have_css("th", text: "CSV file row")
        expect(rendered).to have_css("th", text: "Name and NHS number")
        expect(rendered).to have_css("th", text: "School move")
        expect(rendered).not_to have_css("th", text: "Actions")
      end
    end

    describe "school move to different school (same team)" do
      let(:current_school) { create(:school, team:, name: "Current School") }
      let(:destination_school) { create(:school, team:, name: "New School") }
      let(:patient) do
        create(
          :patient,
          given_name: "John",
          family_name: "Dover",
          nhs_number: "9435797881",
          school: current_school
        )
      end
      let(:records) do
        [
          create(
            :patient_changeset,
            :with_school_move,
            import:,
            patient:,
            row_number: 5,
            school: destination_school
          )
        ]
      end

      it "displays CSV file row number" do
        expect(rendered).to have_css("td", text: "7")
      end

      it "displays patient details" do
        expect(rendered).to have_css("td", text: /DOVER, John/i)
        expect(rendered).to have_css(
          "td .nhsuk-u-secondary-text-colour",
          text: "943 579 7881"
        )
      end

      it "displays school move with 'to' separator" do
        expect(rendered).to have_css("td", text: "Current School")
        expect(rendered).to have_css("td", text: "New School")
        expect(rendered).to have_css(
          "td .nhsuk-u-secondary-text-colour",
          text: "to"
        )
      end

      it "does not show inter-team move message" do
        expect(rendered).not_to have_css(".app-status", text: /moving in from/)
      end
    end

    describe "inter-team move" do
      let(:other_team) { create(:team, name: "Other Team") }
      let(:current_school) do
        create(:school, name: "Current School").tap do |s|
          s.attach_to_team!(other_team, academic_year:)
        end
      end
      let(:destination_school) do
        create(:school, name: "Destination School").tap do |s|
          s.attach_to_team!(team, academic_year:)
        end
      end
      let(:patient) { create(:patient, school: current_school) }
      let(:records) do
        [
          create(
            :patient_changeset,
            :with_school_move,
            import:,
            patient:,
            row_number: 3,
            school: destination_school
          )
        ]
      end

      it "displays inter-team move status message" do
        expect(rendered).to have_css(
          ".app-status",
          text: /This child is moving in from Other Team's area/i
        )
        expect(rendered).to have_css("td", text: "Current School")
        expect(rendered).to have_css("td", text: "Destination School")
      end
    end

    describe "move to home educated" do
      let(:current_school) { create(:school, team:, name: "Current School") }
      let(:patient) { create(:patient, school: current_school) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: 2)]
      end

      before do
        records.first.data["review"]["school_move"] = {
          "school_id" => nil,
          "home_educated" => true
        }
        records.first.save!
      end

      it "displays home educated as destination" do
        expect(rendered).to have_css("td", text: "Home educated")
        expect(rendered).to have_css("td", text: "Current School")
      end
    end

    describe "unknown destination school" do
      let(:current_school) { create(:school, team:, name: "Current School") }
      let(:patient) { create(:patient, school: current_school) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: 1)]
      end

      before do
        records.first.data["review"]["school_move"] = {
          "school_id" => nil,
          "home_educated" => false
        }
        records.first.save!
      end

      it "displays unknown school as destination" do
        expect(rendered).to have_css("td", text: "Unknown school")
      end
    end

    describe "changeset not from file" do
      let(:school) { create(:school, team:) }
      let(:patient) { create(:patient, school:) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: nil)]
      end

      before do
        records.first.data["review"]["school_move"] = {
          "school_id" => school.id,
          "home_educated" => false
        }
        records.first.save!
      end

      it "displays empty string for row number" do
        first_cell = rendered.css("tbody tr td").first
        expect(first_cell.text.strip).to be_empty
        expect(rendered).to have_css("td", text: patient.full_name)
      end
    end

    describe "patient without NHS number" do
      let(:school) { create(:school, team:) }
      let(:patient) { create(:patient, school:, nhs_number: nil) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: 1)]
      end

      before do
        records.first.data["review"]["school_move"] = {
          "school_id" => school.id,
          "home_educated" => false
        }
        records.first.save!
      end

      it "displays not provided for NHS number" do
        expect(rendered).to have_css("td", text: "Not provided")
      end
    end

    describe "patient without school" do
      let(:destination_school) { create(:school, team:, name: "New School") }
      let(:patient) { create(:patient, school: nil) }
      let(:records) do
        [create(:patient_changeset, import:, patient:, row_number: 1)]
      end

      before do
        records.first.data["review"]["school_move"] = {
          "school_id" => destination_school.id,
          "home_educated" => false
        }
        records.first.save!
      end

      it "displays unknown school for current school" do
        expect(rendered).to have_css("td", text: "Unknown school")
        expect(rendered).to have_css("td", text: "New School")
      end
    end

    describe "multiple changesets" do
      let(:school_a) { create(:school, team:, name: "School A") }
      let(:school_b) { create(:school, team:, name: "School B") }
      let(:patient_a) do
        create(
          :patient,
          school: school_a,
          given_name: "Alice",
          family_name: "Smith"
        )
      end
      let(:patient_b) do
        create(
          :patient,
          school: school_a,
          given_name: "Bob",
          family_name: "Jones"
        )
      end
      let(:records) do
        [
          create(
            :patient_changeset,
            import:,
            patient: patient_a,
            row_number: 1
          ),
          create(:patient_changeset, import:, patient: patient_b, row_number: 2)
        ]
      end

      before do
        records.each do |record|
          record.data["review"]["school_move"] = {
            "school_id" => school_b.id,
            "home_educated" => false
          }
          record.save!
        end
      end

      it "renders all changesets with correct information" do
        expect(rendered.css("tbody .nhsuk-table__row").size).to eq(2)
        expect(rendered).to have_css("td", text: /SMITH, Alice/i)
        expect(rendered).to have_css("td", text: /JONES, Bob/i)

        rendered
          .css("tbody .nhsuk-table__row")
          .each do |row|
            expect(row.text).to include("School A")
            expect(row.text).to include("to")
            expect(row.text).to include("School B")
          end
      end
    end

    describe "empty records" do
      let(:records) { [] }

      it "renders empty table body" do
        expect(rendered).to have_css("tbody")
        expect(rendered).not_to have_css("tbody tr")
      end
    end
  end

  describe "with patients (review_screen: false)" do
    let(:review_screen) { false }

    describe "table structure" do
      let(:current_school) { create(:school, team:, name: "Current School") }
      let(:destination_school) { create(:school, team:, name: "New School") }
      let(:patient) { create(:patient, school: current_school) }
      let(:school_move) do
        create(:school_move, patient:, school: destination_school)
      end
      let(:records) do
        Patient.where(id: patient.id).includes(:school, :school_moves)
      end

      before { school_move }

      it "renders table with Actions column" do
        expect(rendered).not_to have_css("th", text: "CSV file row")
        expect(rendered).to have_css("th", text: "Name and NHS number")
        expect(rendered).to have_css("th", text: "School move")
        expect(rendered).to have_css("th", text: "Actions")
      end

      it "displays patient and school move information with review link" do
        expect(rendered).to have_css("td", text: patient.full_name)
        expect(rendered).to have_css("td", text: "Current School")
        expect(rendered).to have_css("td", text: "New School")
        expect(rendered).to have_link(
          "Review",
          href:
            Rails.application.routes.url_helpers.school_move_path(school_move)
        )
      end
    end

    describe "multiple patients" do
      let(:school_a) { create(:school, team:, name: "School A") }
      let(:school_b) { create(:school, team:, name: "School B") }
      let(:patient_a) do
        create(
          :patient,
          school: school_a,
          given_name: "Alice",
          family_name: "Smith"
        )
      end
      let(:patient_b) do
        create(
          :patient,
          school: school_a,
          given_name: "Bob",
          family_name: "Jones"
        )
      end
      let(:school_move_a) do
        create(:school_move, patient: patient_a, school: school_b)
      end
      let(:school_move_b) do
        create(:school_move, patient: patient_b, school: school_b)
      end
      let(:records) do
        Patient.where(id: [patient_a.id, patient_b.id]).includes(
          :school,
          :school_moves
        )
      end

      before do
        school_move_a
        school_move_b
      end

      it "displays review links for all patients" do
        expect(rendered).to have_link(
          "Review",
          href:
            Rails.application.routes.url_helpers.school_move_path(school_move_a)
        )
        expect(rendered).to have_link(
          "Review",
          href:
            Rails.application.routes.url_helpers.school_move_path(school_move_b)
        )
      end
    end

    describe "inter-team move" do
      let(:other_team) { create(:team, name: "Other Team") }
      let(:current_school) do
        create(:school, name: "Current School").tap do |s|
          s.attach_to_team!(other_team, academic_year:)
        end
      end
      let(:destination_school) do
        create(:school, name: "Destination School").tap do |s|
          s.attach_to_team!(team, academic_year:)
        end
      end
      let(:patient) { create(:patient, school: current_school) }
      let(:school_move) do
        create(:school_move, patient:, school: destination_school)
      end
      let(:records) do
        Patient.where(id: patient.id).includes(:school, :school_moves)
      end

      before { school_move }

      it "displays inter-team move status message" do
        expect(rendered).to have_css(
          ".app-status",
          text: /This child is moving in from Other Team's area/i
        )
        expect(rendered).to have_css("td", text: "Current School")
        expect(rendered).to have_css("td", text: "Destination School")
      end
    end
  end
end
