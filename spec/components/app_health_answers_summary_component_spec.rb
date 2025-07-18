# frozen_string_literal: true

describe AppHealthAnswersSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consents.map(&:reload)) }

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
      expect(rendered).to have_content(
        /Second question\?\s*Mum responded: Yes:\s*Notes/
      )
    end
  end

  context "with two consents given" do
    let(:programme) { create(:programme) }
    let(:consents) do
      [
        create(
          :consent,
          :given,
          :from_mum,
          programme:,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(question: "Second question?", response: "no")
          ]
        ),
        create(
          :consent,
          :given,
          :from_dad,
          programme:,
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
      expect(rendered).to have_content(
        /Second question\?\s*Mum responded: No\s*Dad responded: Yes:\s*Notes/
      )
    end
  end

  context "with two consents, one refused" do
    let(:programme) { create(:programme) }
    let(:consents) do
      [
        create(
          :consent,
          :given,
          :from_mum,
          programme:,
          health_answers: [
            HealthAnswer.new(question: "First question?", response: "no"),
            HealthAnswer.new(question: "Second question?", response: "no")
          ]
        ),
        create(:consent, :refused, :from_dad, programme:)
      ]
    end

    it { should have_content(/First question\?\s*Mum responded: No/) }
    it { should have_content(/Second question\?\s*Mum responded: No/) }
  end
end
