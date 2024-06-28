# frozen_string_literal: true

require "rails_helper"

describe AppHealthQuestionsComponent, type: :component do
  subject { page }

  before { render_inline(component) }

  let(:component) { described_class.new(consents:) }

  context "with one consent" do
    let(:consents) do
      [
        create(
          :consent,
          :given,
          :from_mum,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(
              question: "Second question?",
              response: "yes",
              notes: "Notes"
            )
          ]
        )
      ]
    end

    it { should have_content(/First question\?\s*Mum responded: No/) }
    it do
      should have_content(/Second question\?\s*Mum responded: Yes:\s*Notes/)
    end
  end

  context "with two consents given" do
    let(:consents) do
      [
        create(
          :consent,
          :given,
          :from_mum,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(question: "Second question?", response: "no")
          ]
        ),
        create(
          :consent,
          :given,
          :from_dad,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(
              question: "Second question?",
              response: "yes",
              notes: "Notes"
            )
          ]
        )
      ]
    end

    it { should have_content(/First question\?\s*All responded: No/) }
    it do
      should have_content(
               /Second question\?\s*Mum responded: No\s*Dad responded: Yes:\s*Notes/
             )
    end
  end

  context "with two consents, one refused" do
    let(:consents) do
      [
        create(
          :consent,
          :given,
          :from_mum,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(question: "Second question?", response: "no")
          ]
        ),
        create(:consent, :refused, :from_dad)
      ]
    end

    it { should have_content(/First question\?\s*Mum responded: No/) }
    it { should have_content(/Second question\?\s*Mum responded: No/) }
  end
end
