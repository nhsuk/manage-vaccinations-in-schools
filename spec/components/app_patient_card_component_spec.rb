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
      '.nhsuk-summary-list__value[data-testid="full-name"]',
      text: patient.full_name
    )
  end

  it "should render the patient's date of birth" do
    expected_dob = "#{patient.dob.to_fs(:nhsuk_date)} (aged #{patient.age})"
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-testid="dob"]',
      text: expected_dob
    )
  end

  it "should render the patient's NHS number" do
    expect(page).to have_css(
      '.nhsuk-summary-list__value[data-testid="nhs-number"]',
      text: patient.nhs_number
    )
  end

  it "should"
end
