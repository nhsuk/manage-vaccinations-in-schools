# frozen_string_literal: true

describe AppConsentCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(consent, session:) }

  let(:programme) { create(:programme) }
  let(:organisation) { create(:organisation, programmes: [programme]) }

  let(:consent) do
    create(
      :consent,
      patient:,
      parent:,
      programme:,
      organisation:,
      submitted_at: Time.zone.local(2024, 1, 1)
    )
  end
  let(:school) { create(:school, name: "Waterloo Road", organisation:) }
  let(:session) do
    create(:session, programmes: [programme], organisation:, location: school)
  end
  let(:parent) { create(:parent) }
  let(:patient) { create(:patient) }

  it { should have_content(parent.full_name) }

  it { should have_content("Phone number") }
  it { should have_content(parent.phone) }

  it { should have_content("Email address") }
  it { should have_content(parent.email) }

  it { should have_content("Date") }
  it { should have_content("1 January 2024 at 12:00am") }

  it { should have_content("Decision") }
  it { should have_content("Consent given") }

  it { should_not have_content("Consent also given for injected vaccine?") }

  context "when consenting to multiple vaccine methods" do
    let(:programme) { create(:programme, :flu) }

    before { consent.update!(vaccine_methods: %w[nasal injection]) }

    it { should have_content("Decision") }
    it { should have_content("Consent givenNasal spray") }

    it { should have_content("Consent also given for injected vaccine?") }
    it { should have_content("Yes") }
  end
end
