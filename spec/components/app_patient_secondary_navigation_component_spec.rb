describe AppPatientSecondaryNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient:, current_user:) }

  let(:programme) { Programme.hpv }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }
  let(:current_user) { build(:user) }

  let(:allowed) { false }

  let(:available_programmes) { [Programme.hpv, Programme.flu] }

  before do
    stub_authorization(
      allowed: allowed,
      klass: PatientPolicy,
      methods: %i[log?]
    )
    allow(current_user).to receive(:programmes).and_return(available_programmes)
  end

  context "when unauthorised" do
    it "renders nothing" do
      expect(rendered.text).to be_empty
    end
  end

  context "when authorised" do
    let(:allowed) { true }

    context "with the child record tab selected by default" do
      it "renders the navigation with child record tab selected" do
        expect(rendered).to have_css(
          ".app-secondary-navigation",
          text: "Child record"
        )
        expect(rendered).to have_css(".app-secondary-navigation", text: "Flu")
        expect(rendered).to have_css(".app-secondary-navigation", text: "HPV")
        expect(rendered).to have_css(
          ".app-secondary-navigation__current",
          text: "Child record"
        )
      end
    end

    context "with the Flu tab selected" do
      let(:component) do
        described_class.new(patient:, current_user:, selected_tab: "flu")
      end

      it "renders the navigation with Flu tab selected when declared" do
        expect(rendered).to have_css(
          ".app-secondary-navigation",
          text: "Child record"
        )
        expect(rendered).to have_css(".app-secondary-navigation", text: "Flu")
        expect(rendered).to have_css(".app-secondary-navigation", text: "HPV")
        expect(rendered).to have_css(
          ".app-secondary-navigation__current",
          text: "Flu"
        )
      end
    end
  end
end
