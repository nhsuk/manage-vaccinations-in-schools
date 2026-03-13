# frozen_string_literal: true

describe AppPatientNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient, programmes, active:) }

  let(:patient) { create(:patient) }
  let(:active) { nil }
  let(:programmes) { [] }

  before do
    stub_authorization(allowed:, klass: PatientPolicy, methods: %i[log?])
  end

  context "when unauthorised" do
    let(:allowed) { false }

    it { should_not have_link("Child record") }
  end

  context "when authorised" do
    let(:allowed) { true }

    it { should have_link("Child record") }

    context "and child record is selected" do
      let(:active) { :show }

      it do
        expect(rendered).to have_css(
          ".app-secondary-navigation__current",
          text: "Child record"
        )
      end
    end

    context "with programmes" do
      let(:programmes) { [Programme.hpv, Programme.flu] }

      it "renders the programme names in the navigation" do
        expect(rendered).to have_css(".app-secondary-navigation", text: "HPV")
        expect(rendered).to have_css(".app-secondary-navigation", text: "Flu")
      end
    end
  end
end
