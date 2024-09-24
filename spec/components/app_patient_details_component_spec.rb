# frozen_string_literal: true

describe AppPatientDetailsComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }

  let(:parent) { create(:parent) }
  let(:school) { create(:location, :school) }
  let(:patient) do
    create(
      :patient,
      nhs_number: 1_234_567_890,
      common_name: "Homer",
      parents: [parent],
      school:
    )
  end

  it "renders the patient's full name" do
    expect(rendered).to(
      have_css(".nhsuk-summary-list__row", text: "Name\n#{patient.full_name}")
    )
  end

  it "renders the patient's preferred name" do
    expect(rendered).to(
      have_css(".nhsuk-summary-list__row", text: "Known as\nHomer")
    )
  end

  it "renders the patient's date of birth" do
    expected_dob = "#{patient.date_of_birth.to_fs(:long)} (aged #{patient.age})"
    expect(rendered).to(
      have_css(
        ".nhsuk-summary-list__row",
        text: "Date of birth\n#{expected_dob}"
      )
    )
  end

  it "renders the school name" do
    expect(rendered).to(
      have_css(".nhsuk-summary-list__row", text: "School\n#{school.name}")
    )
  end

  it "renders the patient's NHS number" do
    expect(rendered).to(
      have_css(".nhsuk-summary-list__key", text: "NHS number")
    )
    expect(rendered).to(
      have_css(
        ".nhsuk-summary-list__row .app-u-monospace",
        text: "123\u00A0\u200D456\u00A0\u200D7890"
      )
    )
  end

  it "renders the patient's parents" do
    expect(rendered).to(
      have_css(".nhsuk-summary-list__key", text: "Parent or guardian")
    )
    expect(rendered).to(have_css(".nhsuk-summary-list__row", text: parent.name))
    expect(rendered).to(
      have_css(".nhsuk-summary-list__row", text: parent.phone)
    )
  end

  context "without a preferred name" do
    let(:patient) { create(:patient, common_name: nil) }

    it "does not render known as" do
      expect(rendered).not_to(
        have_css(".nhsuk-summary-list__row", text: "Known as")
      )
    end
  end
end
