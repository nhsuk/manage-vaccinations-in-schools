# frozen_string_literal: true

describe AppPatientSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }
  let(:school) { create(:school, name: "Test School") }
  let(:gp_practice) { nil }
  let(:other_school) { create(:school, name: "Other School") }
  let(:parent) { create(:parent, full_name: "Mark Doe") }
  let(:restricted) { false }
  let(:patient) do
    create(
      :patient,
      nhs_number: "1234567890",
      given_name: "John",
      preferred_given_name: "Johnny",
      family_name: "Doe",
      date_of_birth: Date.new(2000, 1, 1),
      gender_code: "male",
      address_line_1: "10 Downing Street",
      address_postcode: "SW1A 1AA",
      school:,
      gp_practice:,
      restricted_at: restricted ? Time.current : nil,
      pending_changes: {
        given_name: "Jane",
        date_of_birth: Date.new(2001, 1, 1),
        address_postcode: "SW1A 2AA",
        school_id: other_school.id
      }
    )
  end

  before do
    create(:parent_relationship, :father, parent:, patient:)
    patient.strict_loading!(false)
  end

  it { should have_content("NHS number") }
  it { should have_content("123\u00A0\u200D456\u00A0\u200D7890") }

  it { should have_content("Full name") }
  it { should have_content("DOE, John") }

  it { should have_content("Known as") }
  it { should have_content("DOE, Johnny") }

  it { should have_content("Date of birth") }
  it { should have_content("1 January 2000") }

  it { should have_content("Gender") }
  it { should have_content("Male") }

  it { should have_content("Address") }
  it { should have_content("10 Downing Street") }

  context "when the patient is restricted" do
    let(:restricted) { true }

    it { should_not have_content("Address") }
    it { should_not have_content("10 Downing Street") }
  end

  it { should have_content("School") }
  it { should have_content("Test School") }

  it { should have_content("Year group") }
  it { should have_content(/Year [0-9]+/) }

  it { should_not have_content("GP surgery") }

  context "with a GP practice" do
    let(:gp_practice) { create(:gp_practice, name: "Waterloo GP") }

    it { should have_content("GP surgery") }
    it { should have_content("Waterloo GP") }
  end

  it { should_not have_css(".app-highlight") }

  context "with pending changes" do
    let(:component) { described_class.new(patient.with_pending_changes) }

    it { should have_css(".app-highlight", text: "DOE, Jane") }
    it { should have_css(".app-highlight", text: "1 January 2001") }
    it { should have_css(".app-highlight", text: "SW1A 2AA") }
    it { should_not have_css(".app-highlight", text: "Male") }
    it { should have_css(".app-highlight", text: "Other School") }

    context "when the patient is restricted" do
      let(:restricted) { true }

      it { should_not have_content("SW1A 2AA") }
    end
  end
end
