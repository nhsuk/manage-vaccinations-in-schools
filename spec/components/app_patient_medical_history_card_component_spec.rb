# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPatientMedicalHistoryCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:health_answers) do
    [
      HealthAnswer.new(
        question: "Is there anything else we should know?",
        response: "no"
      )
    ]
  end
  let(:patient) { FactoryBot.create(:patient) }
  let(:session) { FactoryBot.create(:session) }
  let(:patient_session) { create(:patient_session, patient:, session:) }
  let(:consent) do
    create :consent, patient:, campaign: session.campaign, health_answers:
  end
  let(:triage_notes) { nil }
  let(:triage) { Triage.new(patient_session:) }
  let(:component) { described_class.new(patient:, consent:, triage:) }

  it "renders correctly" do
    expect(page).to have_css(".nhsuk-card")
    expect(page).to have_css(".nhsuk-card__content")
  end

  context "consent given and no triage needed" do
    it "renders correctly" do
      expect(page).to have_css(".nhsuk-card__heading", text: "Medical history")
      expect(page).to have_css("p:first", text: "No triage needed")
      expect(page).to have_css(
        ".nhsuk-details__summary-text",
        text: "Show answers"
      )
    end
  end

  context "health question is yes and triage is done with notes" do
    let(:health_answers) do
      [
        HealthAnswer.new(
          question: "Is there anything else we should know?",
          response: "yes",
          notes: "These are notes"
        )
      ]
    end
    let(:triage_notes) { "These are triage notes" }
    let(:triage) { create :triage, patient_session:, notes: triage_notes }

    it "renders correctly" do
      expect(page).to have_css("h2:nth(2)", text: "Triage notes")
      expect(page).to have_css("p:first", text: triage_notes)
      expect(page).to have_css(
        ".nhsuk-details__summary-text",
        text: "Show answers"
      )
    end
  end

  context "health question is yes and triage is done without notes" do
    let(:health_answers) do
      [
        HealthAnswer.new(
          question: "Is there anything else we should know?",
          response: "yes",
          notes: "These are notes"
        )
      ]
    end
    let(:triage) { create :triage, patient_session:, notes: nil }

    it "renders correctly" do
      expect(page).to have_css("p:first", text: "Triage complete - no notes")
      expect(page).to have_css(
        ".nhsuk-details__summary-text",
        text: "Show answers"
      )
    end
  end

  context "health question is yes but triage is not done" do
    let(:health_answers) do
      [
        HealthAnswer.new(
          question: "Is there anything else we should know?",
          response: "yes",
          notes: "These are notes"
        )
      ]
    end

    it "renders correctly" do
      expect(page).to have_css("p:first", text: "Triage needed")
      expect(page).to have_css("li:first", text: "Health questions need triage")
      expect(page).to have_css(
        ".nhsuk-details__summary-text",
        text: "Show answers"
      )
    end
  end
end
