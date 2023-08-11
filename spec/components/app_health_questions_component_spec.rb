require "rails_helper"

RSpec.describe AppHealthQuestionsComponent, type: :component do
  health_questions = [
    {
      question:
        "Does the child have a disease or treatment that severely affects their immune system?",
      response: "no"
    },
    {
      question:
        "Is anyone in your household having treatment that severely affects their immune system?",
      response: "no"
    },
    { question: "Has your child been diagnosed with asthma?", response: "no" },
    {
      question:
        "Has your child been admitted to intensive care because of a severe egg allergy?",
      response: "no"
    },
    {
      question: "Is there anything else we should know?",
      response: "yes",
      notes:
        "Please be aware my daughter likes to play with needles and will try to grab them"
    }
  ].freeze

  before { render_inline(component) }

  subject { page }

  let(:patient) { FactoryBot.create(:patient) }
  let(:session) { FactoryBot.create(:session) }
  let(:consent) do
    create :consent,
           patient:,
           campaign: session.campaign,
           health_questions:
  end

  let(:component) { described_class.new(consent:) }

  # Copy pasted from the consents factory
  health_questions.each_with_index do |health_question, i|
    it "should have the health question #{i}" do
      expect(page.find_css("h3:nth(#{i + 1})").text).to(
        match(/^\s*#{Regexp.escape(health_question[:question])}\s*$/s)
      )
    end

    it "should have the answer to health question #{i}" do
      if health_question[:response].downcase == "yes"
        expect(page.find_css("p:nth(#{i + 1})").text).to(
          match(/^\s*Yes – #{health_question[:notes]}\s*$/)
        )
      else
        expect(page.find_css("p:nth(#{i + 1})").text).to(match(/^\s*No\s*$/))
      end
    end
  end
end
