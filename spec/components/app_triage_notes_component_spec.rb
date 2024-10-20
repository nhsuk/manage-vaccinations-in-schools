# frozen_string_literal: true

describe AppTriageNotesComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programme:) }
  let(:patient) { patient_session.patient }

  context "triage notes are not present" do
    it "does not render" do
      expect(component).not_to be_render
    end
  end

  context "a single triage note is present" do
    around do |example|
      travel_to(Time.zone.local(2023, 12, 4, 10, 4)) { example.run }
    end

    let(:performed_by) { create(:user, family_name: "Gear", given_name: "Joe") }

    before do
      create(
        :triage,
        :ready_to_vaccinate,
        programme:,
        notes: "Some notes",
        patient:,
        performed_by:
      )
    end

    it "renders" do
      expect(component.render?).to be true
    end

    it { should have_css("h3", text: "Triaged decision: Safe to vaccinate") }
    it { should have_css("p", text: patient_session.triages.first.notes) }
    it { should have_css("p", text: "4 December 2023 at 10:04am") }
    it { should have_css("p", text: "Joe Gear") }
    it { should_not have_css("hr") }
  end

  context "multiple triage notes are present" do
    before { create_list(:triage, 2, programme:, patient:) }

    it "renders" do
      expect(component).to be_render
    end

    it { should have_css("hr") }
  end
end
