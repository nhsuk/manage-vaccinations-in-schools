# frozen_string_literal: true

describe AppConsentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }

  let(:consent) { create(:consent) }

  it { should have_content("Programme") }
  it { should have_content("Method") }
  it { should have_content("Decision") }

  context "when recorded" do
    let(:consent) { create(:consent) }

    it { should have_content("Date") }
  end

  context "when refused" do
    let(:consent) { create(:consent, :refused) }

    it { should have_content("Reason for refusal") }
  end

  context "when withdrawn" do
    let(:consent) { create(:consent, :withdrawn) }

    it { should have_content("Consent givenWithdrawn") }
  end

  context "with notes" do
    let(:consent) { create(:consent, :refused, notes: "Some notes.") }

    it { should have_content("Notes") }
  end

  it { should_not have_content("Consent also given for injected vaccine?") }

  context "when consenting to multiple vaccine methods" do
    let(:programme) { create(:programme, :flu) }
    let(:consent) do
      create(:consent, programme:, vaccine_methods: %w[nasal injection])
    end

    it { should have_content("Decision") }
    it { should have_content("Consent givenNasal spray") }

    it { should have_content("Consent also given for injected vaccine?") }
    it { should have_content("Yes") }
  end
end
