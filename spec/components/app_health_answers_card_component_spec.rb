# frozen_string_literal: true

describe AppHealthAnswersCardComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new(consents.map(&:reload), heading: "Health answers")
  end

  let(:consents) do
    [
      create(
        :consent,
        :given,
        :from_mum,
        health_answers: [
          HealthAnswer.new(question: "First question?", response: "no")
        ]
      )
    ]
  end

  it { should have_content("Health answers") }
  it { should have_content("First question") }
  it { should have_content("Mum responded: No") }
end
