require "rails_helper"

describe ConsolidatedHealthAnswers do
  it "returns a questionnaire from one responder in the order it was given, including notes" do
    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "No"
    )
    subject.add_answer(
      responder: "Mum",
      question: "Second question?",
      answer: "No"
    )
    subject.add_answer(
      responder: "Mum",
      question: "Third question?",
      answer: "Yes",
      notes: "Notes"
    )

    expect(subject.to_h).to eq(
      {
        "First question?" => [{ responder: "Mum", answer: "No", notes: nil }],
        "Second question?" => [{ responder: "Mum", answer: "No", notes: nil }],
        "Third question?" => [
          { responder: "Mum", answer: "Yes", notes: "Notes" }
        ]
      }
    )
  end

  it "groups answers from multiple responders to the same question" do
    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "No"
    )
    subject.add_answer(
      responder: "Dad",
      question: "First question?",
      answer: "Yes",
      notes: "Notes"
    )

    expect(subject.to_h).to eq(
      {
        "First question?" => [
          { responder: "Mum", answer: "No", notes: nil },
          { responder: "Dad", answer: "Yes", notes: "Notes" }
        ]
      }
    )
  end

  it "consolidates answers to the same question" do
    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "No"
    )
    subject.add_answer(
      responder: "Dad",
      question: "First question?",
      answer: "No"
    )

    expect(subject.to_h).to eq(
      { "First question?" => [{ responder: "All", answer: "No", notes: nil }] }
    )
  end

  it "correctly handles several responses from the same parent (or two same-sex parents)" do
    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "Yes",
      notes: "Notes"
    )

    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "Yes",
      notes: "Different notes"
    )

    expect(subject.to_h).to eq(
      {
        "First question?" => [
          { responder: "Mum", answer: "Yes", notes: "Notes" },
          { responder: "Mum", answer: "Yes", notes: "Different notes" }
        ]
      }
    )
  end

  it "handles consent forms with variable numbers of questions, when some questions branch" do
    subject.add_answer(
      responder: "Mum",
      question: "First question?",
      answer: "Yes"
    )
    subject.add_answer(
      responder: "Mum",
      question: "Second question?",
      answer: "Yes",
      notes: "Notes"
    )

    subject.add_answer(
      responder: "Dad",
      question: "First question?",
      answer: "No"
    )

    expect(subject.to_h).to eq(
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
