require "rails_helper"

RSpec.describe AppPatientCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:patient) { FactoryBot.create(:patient) }
  let(:session) { FactoryBot.create(:session) }
  let(:component) { described_class.new(patient:, session:) }

  it { should have_css(".nhsuk-card") }
  it { should have_css(".nhsuk-card__content") }
  it { should have_css(".nhsuk-card__heading", text: "Child details") }

  it "should render the patient's full name" do
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-child-vaccination-target="fullName"]',
      text: patient.full_name
    )
  end

  it "should render the patient's date of birth" do
    expected_dob = "#{patient.dob.strftime("%d %B %Y")} (aged #{patient.age})"
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-child-vaccination-target="dob"]',
      text: expected_dob
    )
  end

  it "should render the patient's GP" do
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-child-vaccination-target="gp"]',
      text: patient.gp
    )
  end

  it "should render the patient's NHS number" do
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-child-vaccination-target="nhsNumber"]',
      text: patient.nhs_number
    )
  end
end
