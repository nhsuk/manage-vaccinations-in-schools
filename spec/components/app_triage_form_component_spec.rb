require "rails_helper"

describe AppTriageFormComponent, type: :component do
  describe "#initialize" do
    let(:patient_session) { create :patient_session }
    let(:triage) { nil }
    let(:component) do
      described_class.new(
        patient_session:,
        triage:,
        section: :triage,
        tab: :needed
      )
    end

    before { render_inline(component) }

    subject { page }

    it { should have_text("Is it safe to vaccinate") }
    it { should have_css(".app-fieldset__legend--reset") }

    describe "triage instance variable" do
      subject { component.instance_variable_get(:@triage) }

      context "patient_session has no existing triage" do
        it "creates a new Triage object" do
          should be_a Triage
        end
      end

      context "patient_session has existing triage" do
        let(:old_triage) { create :triage, :kept_in_triage }
        let(:patient_session) { create :patient_session, triage: [old_triage] }

        it { should_not eq triage }
        it { should be_needs_follow_up } # AKA kept_in_triage
      end
    end

    describe "with a bold legend" do
      context "when true" do
        let(:component) do
          described_class.new(
            patient_session:,
            triage:,
            section: :triage,
            tab: :needed,
            bold_legend: true
          )
        end

        it { should have_css("h2") }
        it { should_not have_css(".app-fieldset__legend--reset") }
      end
    end
  end
end
