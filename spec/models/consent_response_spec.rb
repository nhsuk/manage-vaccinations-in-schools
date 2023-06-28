require "rails_helper"

RSpec.describe ConsentResponse do
  describe "when consent given by parent or guardian, all health questions are no" do
    it "does not require triage" do
      response = build(:consent_given, parent_relationship: :mother)

      expect(response).not_to be_triage_needed
    end
  end

  describe "when consent given by someone who's not a parent or a guardian" do
    it "does require triage" do
      response = build(:consent_given, parent_relationship: :other)

      expect(response).to be_triage_needed
    end
  end

  describe "when consent given by parent or guardian, but some info for health questions" do
    it "does require triage" do
      health_responses = [
        {
          question:
            "Does the child have a disease or treatment that severely affects their immune system?",
          response: "yes"
        }
      ]
      response =
        build(
          :consent_given,
          parent_relationship: :mother,
          health_questions: health_responses
        )

      expect(response).to be_triage_needed
    end
  end
end
