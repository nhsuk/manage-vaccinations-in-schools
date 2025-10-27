# frozen_string_literal: true

describe AppConsentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }

  let(:consent) { create(:consent) }

  it { should_not have_content("Programme") }

  context "when showing the programme" do
    let(:component) { described_class.new(consent, show_programme: true) }

    it { should have_content("Programme") }
  end

  it { should_not have_content("Method") }

  context "when showing the route" do
    let(:component) { described_class.new(consent, show_route: true) }

    it { should have_content("Method") }
  end

  it { should have_content("Response") }

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

    it { should_not have_content("Notes") }

    context "when showing the notes" do
      let(:component) { described_class.new(consent, show_notes: true) }

      it { should have_content("NotesSome notes.") }
    end
  end

  it { should_not have_content("Confirmation of vaccination sent to parent?") }

  context "when the child doesn't want the parents to know about the vaccination" do
    let(:consent) { create(:consent, :given, :self_consent) }
    let(:component) { described_class.new(consent, show_notify_parent: true) }

    it do
      expect(rendered).to have_content(
        "Confirmation of vaccination sent to parent?No"
      )
    end
  end

  context "when the child wants the parents to know about the vaccination" do
    let(:consent) do
      create(:consent, :given, :self_consent, :notify_parents_on_vaccination)
    end
    let(:component) { described_class.new(consent, show_notify_parent: true) }

    it do
      expect(rendered).to have_content(
        "Confirmation of vaccination sent to parent?Yes"
      )
    end
  end

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

      it { should have_content("Response") }
      it { should have_content("Consent givenNasal spray") }

      it { should have_content("Consent also given for injected vaccine?") }
      it { should have_content("Yes") }
    end
  end
end
