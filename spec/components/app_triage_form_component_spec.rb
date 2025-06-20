# frozen_string_literal: true

describe AppTriageFormComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(triage_form, url:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:patient) { patient_session.patient }

  let(:triage_form) { TriageForm.new(patient_session:, programme:) }
  let(:url) { "/triage" }

  it { should have_css("h2") }
  it { should have_text("Is it safe to vaccinate") }
  it { should_not have_css(".app-fieldset__legend--reset") }

  describe "without a heading" do
    let(:component) { described_class.new(triage_form, url:, heading: false) }

    it { should have_css(".app-fieldset__legend--reset") }
  end
end
