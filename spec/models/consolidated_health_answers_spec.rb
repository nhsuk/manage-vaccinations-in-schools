# frozen_string_literal: true

describe ConsolidatedHealthAnswers do
  subject(:to_h) { consolidated_health_answers.to_h }

  let(:consolidated_health_answers) { described_class.new }

  context "with one responder in the order it was given, including notes" do
    before do
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "No"
      )
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "Second question?",
        answer: "No"
      )
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "Third question?",
        answer: "Yes",
        notes: "Notes"
      )
      consolidated_health_answers.add_answer(
        responder: nil,
        question: "Follow up question?",
        answer: nil,
        notes: nil
      )
    end

    it do
      expect(to_h).to eq(
        {
          "First question?" => [{ responder: "Mum", answer: "No", notes: nil }],
          "Second question?" => [
            { responder: "Mum", answer: "No", notes: nil }
          ],
          "Third question?" => [
            { responder: "Mum", answer: "Yes", notes: "Notes" }
          ]
        }
      )
    end
  end

  context "with multiple responders to the same question" do
    before do
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "No"
      )
      consolidated_health_answers.add_answer(
        responder: "Dad",
        question: "First question?",
        answer: "Yes",
        notes: "Notes"
      )
    end

    it do
      expect(to_h).to eq(
        {
          "First question?" => [
            { responder: "Mum", answer: "No", notes: nil },
            { responder: "Dad", answer: "Yes", notes: "Notes" }
          ]
        }
      )
    end
  end

  context "with same answers to the same question" do
    before do
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "No"
      )
      consolidated_health_answers.add_answer(
        responder: "Dad",
        question: "First question?",
        answer: "No"
      )
    end

    it do
      expect(to_h).to eq(
        {
          "First question?" => [{ responder: "All", answer: "No", notes: nil }]
        }
      )
    end
  end

  context "with several responses from the same parent (or two same-sex parents)" do
    before do
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "Yes",
        notes: "Notes"
      )

      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "Yes",
        notes: "Different notes"
      )
    end

    it do
      expect(to_h).to eq(
        {
          "First question?" => [
            { responder: "Mum", answer: "Yes", notes: "Notes" },
            { responder: "Mum", answer: "Yes", notes: "Different notes" }
          ]
        }
      )
    end
  end

  context "with consent forms with variable numbers of questions, when some questions branch" do
    before do
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "First question?",
        answer: "Yes"
      )
      consolidated_health_answers.add_answer(
        responder: "Mum",
        question: "Second question?",
        answer: "Yes",
        notes: "Notes"
      )
      consolidated_health_answers.add_answer(
        responder: "Dad",
        question: "First question?",
        answer: "No"
      )
    end

    it do
      expect(to_h).to eq(
        {
          "First question?" => [
            { responder: "Mum", answer: "Yes", notes: nil },
            { responder: "Dad", answer: "No", notes: nil }
          ],
          "Second question?" => [
            { responder: "Mum", answer: "Yes", notes: "Notes" }
          ]
        }
      )
    end
  end
end
