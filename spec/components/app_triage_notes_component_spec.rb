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
    prepend_before(:context) do
      Timecop.freeze(Time.zone.local(2023, 12, 4, 10, 4))
    end

    after(:context) { Timecop.return }

    let(:user) { create(:user, full_name: "Joe Gear") }
    let(:triage) { [create(:triage, notes: "Some notes", user:)] }

    it "renders" do
      expect(component.render?).to be_truthy
    end

    it { should have_css("p", text: patient_session.triage.first.notes) }
    it { should have_css("p", text: "Joe Gear, 4 December 2023 at 10:04") }
    it { should_not have_css("ul") }
  end

  context "multiple triage notes are present" do
    let(:triage) do
      [
        create(:triage, notes: "Some notes"),
        create(:triage, notes: "More notes")
      ]
    end

    it "renders" do
      expect(component.render?).to be_truthy
    end

    it { should have_css("ul p", text: "Some notes") }
    it { should have_css("ul p", text: "More notes") }
  end
end
