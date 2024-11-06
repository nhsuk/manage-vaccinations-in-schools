# frozen_string_literal: true

describe AppConsentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }

  let(:consent) { create(:consent) }

  it { should have_content("Decision") }
  it { should have_content("Response method") }

  context "when recorded" do
    let(:consent) { create(:consent, :recorded) }

    it { should have_content("Response date") }
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
end
