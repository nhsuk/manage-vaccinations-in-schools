# frozen_string_literal: true

describe AppPatientSummaryComponent, type: :component do
  subject { page }

  before { render_inline(component) }

  let(:component) { described_class.new(patient:) }
  let(:school) { create(:location, :school, name: "Test School") }
  let(:other_school) { create(:location, :school, name: "Other School") }
  let(:patient) do
    create(
      :patient,
      nhs_number: "1234567890",
      first_name: "John",
      last_name: "Doe",
      date_of_birth: Date.new(2000, 1, 1),
      gender_code: "male",
      address_postcode: "SW1A 1AA",
      school:,
      pending_changes: {
        first_name: "Jane",
        date_of_birth: Date.new(2001, 1, 1),
        address_postcode: "SW1A 2AA",
        school_id: other_school.id
      }
    )
  end

  it { should have_content("NHS number") }
  it { should have_content("123\u00A0\u200D456\u00A0\u200D7890") }

  it { should have_content("Full name") }
  it { should have_content("John Doe") }

  it { should have_content("Date of birth") }
  it { should have_content("1 January 2000") }

  it { should have_content("Sex") }
  it { should have_content("Male") }

  it { should have_content("Postcode") }
  it { should have_content("SW1A 1AA") }

  it { should have_content("School") }
  it { should have_content("Test School") }

  it { should_not have_css(".app-highlight") }

  context "with pending changes" do
    let(:component) do
      described_class.new(patient: patient.with_pending_changes)
    end

    it { should have_css(".app-highlight", text: "Jane Doe") }
    it { should have_css(".app-highlight", text: "1 January 2001") }
    it { should have_css(".app-highlight", text: "SW1A 2AA") }
    it { should_not have_css(".app-highlight", text: "Male") }
    it { should have_css(".app-highlight", text: "Other School") }
  end
end
