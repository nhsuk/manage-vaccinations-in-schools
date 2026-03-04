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
    it { should_not have_link("Activity log") }
  end

  context "when authorised" do
    let(:allowed) { true }

    it { should have_link("Child record") }
    it { should have_link("Activity log") }

    context "and child record is selected" do
      let(:active) { :show }

      it do
        expect(rendered).to have_css(
          ".app-secondary-navigation__current",
          text: "Child record"
        )
      end
    end

    context "and activity log is selected" do
      let(:active) { :log }

      it do
        expect(rendered).to have_css(
          ".app-secondary-navigation__current",
          text: "Activity log"
        )
      end
    end

    context "with programmes" do
      let(:programmes) { [Programme.hpv, Programme.flu] }

      context "and the child record redesign feature flag is enabled" do
        before { Flipper.enable(:child_record_redesign) }

        it "renders the programme names in the navigation" do
          expect(rendered).to have_css(".app-secondary-navigation", text: "HPV")
          expect(rendered).to have_css(".app-secondary-navigation", text: "Flu")
        end
      end

      context "and the child record redesign feature flag is disabled" do
        before { Flipper.disable(:child_record_redesign) }

        it "renders the programme names in the navigation" do
          expect(rendered).not_to have_css(
            ".app-secondary-navigation",
            text: "HPV"
          )
          expect(rendered).not_to have_css(
            ".app-secondary-navigation",
            text: "Flu"
          )
        end
      end
    end
  end
end
