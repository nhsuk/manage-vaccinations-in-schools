require "rails_helper"

RSpec.describe AppHealthQuestionsComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:patient) { FactoryBot.create(:patient) }
  let(:session) { FactoryBot.create(:session) }
  let(:consent_response) do
    create :consent_response, patient:, campaign: session.campaign
  end

  let(:component) { described_class.new(consent_response:) }

  # Copy pasted from the consent_responses factory
  [
    {
      question:
        "Does the child have a disease or treatment that severely affects their immune system?",
      response: "No"
    },
    {
      question:
        "Is anyone in your household having treatment that severely affects their immune system?",
      response: "No"
    },
    { question: "Has your child been diagnosed with asthma?", response: "No" },
    {
      question:
        "Has your child been admitted to intensive care because of a severe egg allergy?",
      response: "No"
    },
    { question: "Is there anything else we should know?", response: "No" }
  ].each_with_index do |health_question, i|
    it "should have the health question #{i}" do
      expect(page.find_css("h3:nth(#{i + 1})").text).to(
        match(/^\s*#{Regexp.escape(health_question[:question])}\s*$/s)
      )
    end

    it "should have the answer to health question #{i}" do
      expect(page.find_css("p:nth(#{i + 1})").text).to(
        match(/^\s*#{health_question[:response]}\s*$/)
      )
    end
  end
end
