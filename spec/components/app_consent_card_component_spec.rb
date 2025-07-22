# frozen_string_literal: true

describe AppConsentCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(consent, session:) }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }

  let(:consent) do
    create(
      :consent,
      patient:,
      parent:,
      programme:,
      team:,
      submitted_at: Time.zone.local(2024, 1, 1)
    )
  end
  let(:school) { create(:school, name: "Waterloo Road", team:) }
  let(:session) do
    create(:session, programmes: [programme], team:, location: school)
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

  context "with the flu programme" do
    let(:programme) { create(:programme, :flu) }
    let(:consent) { create(:consent, programme:, vaccine_methods: %w[nasal]) }

    it { should have_content("Consent also given for injected vaccine?") }
    it { should have_content("No") }

    context "and consenting to multiple vaccine methods" do
      let(:consent) do
        create(:consent, programme:, vaccine_methods: %w[nasal injection])
      end

      it { should have_content("Decision") }
      it { should have_content("Consent givenNasal spray") }

      it { should have_content("Consent also given for injected vaccine?") }
      it { should have_content("Yes") }
    end
  end
end
