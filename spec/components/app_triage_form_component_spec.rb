# frozen_string_literal: true

describe AppTriageFormComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:patient) { patient_session.patient }

  it { should have_text("Is it safe to vaccinate") }
  it { should have_css(".app-fieldset__legend--reset") }

  describe "triage private method" do
    subject { component.send(:triage) }

    context "patient_session has no existing triage" do
      it { should be_a(Triage) }
    end

    context "patient_session has existing triage" do
      before { create(:triage, :needs_follow_up, programme:, patient:) }

      it { should_not be_nil }
      it { should be_needs_follow_up }
    end
  end

  describe "with a bold legend" do
    let(:component) do
      described_class.new(patient_session:, programme:, legend: :bold)
    end

    it { should have_css("h2") }
    it { should_not have_css(".app-fieldset__legend--reset") }
  end

  describe "with a hidden legend" do
    let(:component) do
      described_class.new(patient_session:, programme:, legend: :hidden)
    end

    it { should have_css("legend.nhsuk-visually-hidden") }
  end

  describe "with an existing triage" do
    let(:component) do
      described_class.new(patient_session:, programme:, triage:)
    end

    let(:triage) { create(:triage, programme:) }

    it { should have_text("Continue") }
  end
end
