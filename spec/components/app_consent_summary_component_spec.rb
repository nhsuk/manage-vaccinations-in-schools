require "rails_helper"

RSpec.describe AppConsentSummaryComponent, type: :component do
  let(:component) do
    described_class.new(
      name: "Jane Smith",
      relationship: "Mum",
      contact: {
        phone: "07987654321",
        email: "jane@example.com"
      },
      response: {
        text: "Consent refused (online)",
        timestamp: Time.zone.local(2024, 3, 1, 14, 23, 0)
      },
      refusal_reason: {
        reason: "already vaccinated",
        notes: "Vaccinated at the GP"
      }
    )
  end

  subject { page }

  before { render_inline(component) }

  it { should have_text("Jane Smith") }
  it { should have_text("Mum") }
  it { should have_text("07987654321") }
  it { should have_text("jane@example.com") }
  it { should have_text("Consent refused (online)") }
  it { should have_text("1 Mar 2024 at 2:23pm") }
  it do
    should have_text("Refusal reasonAlready vaccinatedVaccinated at the GP")
  end
end
