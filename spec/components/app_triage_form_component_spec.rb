# frozen_string_literal: true

describe AppTriageFormComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:patient_session) { create(:patient_session) }
  let(:component) { described_class.new(patient_session:, url: "#") }

  it { should have_text("Is it safe to vaccinate") }
  it { should have_css(".app-fieldset__legend--reset") }

  describe "triage instance variable" do
    subject { component.instance_variable_get(:@triage) }

    context "patient_session has no existing triage" do
      it "creates a new Triage object" do
        expect(subject).to be_a Triage
      end
    end

    context "patient_session has existing triage" do
      before { create(:triage, :needs_follow_up, patient_session:) }

      it { should_not be_nil }
      it { should be_needs_follow_up }
    end
  end

  describe "with a bold legend" do
    let(:component) do
      described_class.new(patient_session:, url: "#", legend: :bold)
    end

    it { should have_css("h2") }
    it { should_not have_css(".app-fieldset__legend--reset") }
  end

  describe "with a hidden legend" do
    let(:component) do
      described_class.new(patient_session:, url: "#", legend: :hidden)
    end

    it { should have_css("legend.nhsuk-visually-hidden") }
  end

  describe "with the put method" do
    let(:component) do
      described_class.new(patient_session:, url: "#", method: :put)
    end

    it { should have_text("Continue") }
  end
end
