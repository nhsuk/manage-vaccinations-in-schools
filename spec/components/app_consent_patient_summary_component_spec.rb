# frozen_string_literal: true

describe AppConsentPatientSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }

  let(:consent) { create(:consent, patient:, consent_form:, programme:, team:) }
  let(:school) { create(:location, :school, name: "Waterloo Road", team:) }
  let(:session) { create(:session, programme:, team:, location: school) }
  let(:consent_form) do
    create(
      :consent_form,
      address_postcode: "SW1A 1AA",
      gp_name: "Waterloo GP",
      session:
    )
  end

  let(:restricted) { false }
  let(:patient) do
    create(
      :patient,
      given_name: "John",
      family_name: "Doe",
      date_of_birth: Date.new(2000, 1, 1),
      school:,
      team:,
      restricted_at: restricted ? Time.current : nil
    )
  end

  it { should have_content("Full name") }
  it { should have_content("John Doe") }

  it { should have_content("Date of birth") }
  it { should have_content("1 January 2000") }

  it { should have_content("Home address") }
  it { should have_content("SW1A 1AA") }

  it { should have_content("GP surgery") }
  it { should have_content("Waterloo GP") }

  it { should have_content("School") }
  it { should have_content("Waterloo Road") }

  context "with a restricted patient" do
    let(:restricted) { true }

    it { should_not have_content("GP surgery") }
    it { should_not have_content("Waterloo GP") }

    it { should_not have_content("Home address") }
    it { should_not have_content("SW1A 1AA") }
  end
end
