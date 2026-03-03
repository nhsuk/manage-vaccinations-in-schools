# frozen_string_literal: true

describe AppPatientNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient, active:) }

  let(:patient) { create(:patient) }
  let(:active) { nil }

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
  end
end
