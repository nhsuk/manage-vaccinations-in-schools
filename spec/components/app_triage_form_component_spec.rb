# frozen_string_literal: true

describe AppTriageFormComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(model:, url:) }

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  let(:model) { Triage.new(patient:, programme:) }
  let(:url) { "/triage" }

  it { should have_css("h2") }
  it { should have_text("Is it safe to vaccinate") }
  it { should_not have_css(".app-fieldset__legend--reset") }

  describe "without a heading" do
    let(:component) { described_class.new(model:, url:, heading: false) }

    it { should have_css(".app-fieldset__legend--reset") }
  end
end
