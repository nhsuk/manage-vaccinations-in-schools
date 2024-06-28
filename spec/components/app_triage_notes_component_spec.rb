# frozen_string_literal: true

require "rails_helper"

describe AppTriageNotesComponent, type: :component do
  before { render_component }

  subject { page }

  let(:component) { described_class.new(patient_session:) }
  let(:render_component) { render_inline(component) }
  let(:patient_session) { create(:patient_session, triage:) }
  let(:triage) { [] }

  context "triage notes are not present" do
    it "does not render" do
      expect(component.render?).to be_falsey
    end
  end

  context "a single triage note is present" do
    around(:all) do |example|
      Timecop.freeze(Time.zone.local(2023, 12, 4, 10, 4)) { example.run }
    end

    let(:user) { create(:user, full_name: "Joe Gear") }
    let(:triage) do
      [create(:triage, :ready_to_vaccinate, notes: "Some notes", user:)]
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
    let(:triage) { create_list(:triage, 2) }

    it "renders" do
      expect(component.render?).to be_truthy
    end

    it { should have_css("hr") }
  end
end
