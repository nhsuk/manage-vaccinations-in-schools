# frozen_string_literal: true

describe AppConsentRefusedTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(Consent.all) }

  let(:programme) { create(:programme) }

  before do
    create(
      :consent,
      :refused,
      programme:,
      reason_for_refusal: :contains_gelatine
    )
    create(
      :consent,
      :refused,
      programme:,
      reason_for_refusal: :already_vaccinated
    )
    create(
      :consent,
      :refused,
      programme:,
      reason_for_refusal: :will_be_vaccinated_elsewhere
    )
    create(:consent, :refused, programme:, reason_for_refusal: :medical_reasons)
    create(:consent, :refused, programme:, reason_for_refusal: :personal_choice)
    create(:consent, :refused, programme:, reason_for_refusal: :other)
  end

  it { should have_content("Contains gelatine\n\n            16.7%") }
  it { should have_content("Already vaccinated\n\n            16.7%") }

  it do
    expect(rendered).to have_content(
      "Will be vaccinated elsewhere\n\n            16.7%"
    )
  end

  it { should have_content("Medical reasons\n\n            16.7%") }
  it { should have_content("Personal choice\n\n            16.7%") }
  it { should have_content("Other\n\n            16.7%") }
end
