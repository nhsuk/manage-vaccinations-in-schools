# frozen_string_literal: true

describe AppPatientSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }
  let(:school) { create(:location, :school, name: "Test School") }
  let(:other_school) { create(:location, :school, name: "Other School") }
  let(:parent) { create(:parent, name: "Mark Doe") }
  let(:patient) do
    create(
      :patient,
      nhs_number: "1234567890",
      first_name: "John",
      last_name: "Doe",
      date_of_birth: Date.new(2000, 1, 1),
      gender_code: "male",
      address_line_1: "10 Downing Street",
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

  before { create(:parent_relationship, :father, parent:, patient:) }

  it { should have_content("NHS number") }
  it { should have_content("123\u00A0\u200D456\u00A0\u200D7890") }

  it { should have_content("Full name") }
  it { should have_content("John Doe") }

  context "when showing the common name" do
    let(:component) { described_class.new(patient, show_common_name: true) }

    before { patient.update!(common_name: "Johnny") }

    it { should have_content("Known as") }
    it { should have_content("Johnny") }
  end

  it { should have_content("Date of birth") }
  it { should have_content("1 January 2000") }
  it { should have_content(/Year [0-9]+/) }

  it { should have_content("Sex") }
  it { should have_content("Male") }

  it { should have_content("Postcode") }
  it { should have_content("SW1A 1AA") }

  context "when showing the address" do
    let(:component) { described_class.new(patient, show_address: true) }

    it { should_not have_content("Postcode") }
    it { should have_content("Address") }
    it { should have_content("10 Downing Street") }
  end

  it { should have_content("School") }
  it { should have_content("Test School") }

  context "when showing parents or guardians" do
    let(:component) do
      described_class.new(patient, show_parent_or_guardians: true)
    end

    it { should have_content("Parent or guardian") }
    it { should have_content("Mark Doe (Dad)") }
  end

  it { should_not have_css(".app-highlight") }

  context "with pending changes" do
    let(:component) { described_class.new(patient.with_pending_changes) }

    it { should have_css(".app-highlight", text: "Jane Doe") }
    it { should have_css(".app-highlight", text: "1 January 2001") }
    it { should have_css(".app-highlight", text: "SW1A 2AA") }
    it { should_not have_css(".app-highlight", text: "Male") }
    it { should have_css(".app-highlight", text: "Other School") }
  end
end
