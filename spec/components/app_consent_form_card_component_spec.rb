# frozen_string_literal: true

describe AppConsentFormCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(consent_form) }

  let(:consent_form) do
    create(
      :consent_form,
      parent_full_name: "Jane Smith",
      parent_relationship_type: :mother,
      parent_phone: "07987 654321",
      parent_email: "jane@example.com",
      response: :refused,
      recorded_at: Time.zone.local(2024, 3, 1, 14, 23, 0),
      reason_for_refusal: "already_vaccinated",
      reason_for_refusal_notes: "Vaccinated at the GP"
    )
  end

  it { should have_text("Consent refused (online)") }
  it { should have_text("1 March 2024 at 2:23pm") }
  it { should have_text("Vaccine already received") }
  it { should have_text("Vaccinated at the GP") }
end
