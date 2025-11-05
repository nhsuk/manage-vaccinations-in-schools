# frozen_string_literal: true

describe AppConsentRefusedTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(consents, vaccine_may_contain_gelatine:)
  end

  let(:consents) { Consent.all }
  let(:vaccine_may_contain_gelatine) { true }

  let(:programme) { CachedProgramme.sample }

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

  it { should have_content("Contains gelatine\n            16.7%") }
  it { should have_content("Already vaccinated\n            16.7%") }

  it do
    expect(rendered).to have_content(
      "Will be vaccinated elsewhere\n            16.7%"
    )
  end

  it { should have_content("Medical reasons\n            16.7%") }
  it { should have_content("Personal choice\n            16.7%") }
  it { should have_content("Other\n            16.7%") }

  context "when no vaccine contains gelatine" do
    let(:vaccine_may_contain_gelatine) { false }

    it { should_not have_content("Contains gelatine") }
  end
end
