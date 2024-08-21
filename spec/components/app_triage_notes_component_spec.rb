# frozen_string_literal: true

require "rails_helper"

describe AppTriageNotesComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:) }
  let(:patient_session) { create(:patient_session) }

  context "triage notes are not present" do
    it "does not render" do
      expect(component).not_to be_render
    end
  end

  context "a single triage note is present" do
    around do |example|
      Timecop.freeze(Time.zone.local(2023, 12, 4, 10, 4)) { example.run }
    end

    let(:user) { create(:user, family_name: "Gear", given_name: "Joe") }

    before do
      create(
        :triage,
        :ready_to_vaccinate,
        notes: "Some notes",
        user:,
        patient_session:
      )
    end

    it "renders" do
      expect(component.render?).to be true
    end

    it { should have_css("h3", text: "Triaged decision: Safe to vaccinate") }
    it { should have_css("p", text: patient_session.triage.first.notes) }
    it { should have_css("p", text: "4 December 2023 at 10:04am") }
    it { should have_css("p", text: "Joe Gear") }
    it { should_not have_css("hr") }
  end

  context "multiple triage notes are present" do
    before { create_list(:triage, 2, patient_session:) }

    it "renders" do
      expect(component).to be_render
    end

    it { should have_css("hr") }
  end
end
