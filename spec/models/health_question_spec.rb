# frozen_string_literal: true

# == Schema Information
#
# Table name: health_questions
#
#  id                    :bigint           not null, primary key
#  hint                  :string
#  metadata              :jsonb            not null
#  question              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  follow_up_question_id :bigint
#  next_question_id      :bigint
#  vaccine_id            :bigint           not null
#
# Indexes
#
#  index_health_questions_on_follow_up_question_id  (follow_up_question_id)
#  index_health_questions_on_next_question_id       (next_question_id)
#  index_health_questions_on_vaccine_id             (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (follow_up_question_id => health_questions.id)
#  fk_rails_...  (next_question_id => health_questions.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
require "rails_helper"

describe HealthQuestion do
  let(:vaccine) do
    create :vaccine, type: "tester", brand: "Tester", method: "injection"
  end

  describe ".first_health_question" do
    let!(:hq1) { create :health_question, vaccine: }
    let!(:hq2) { create :health_question, vaccine: }
    let!(:hq3) { create :health_question, vaccine: }

    it "returns the first health question" do
      hq1.update! next_question: hq2
      hq2.update! next_question: hq3

      expect(vaccine.health_questions.first_health_question).to eq(hq1)
    end

    it "raises an error if there is no first question" do
      hq1.update! next_question: hq2
      hq2.update! next_question: hq3
      hq3.update! next_question: hq1

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "No first question found"
      )
    end

    it "raises an error if there is more than one first question" do
      hq2.update! next_question: hq3

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "More than one first question found"
      )
    end

    it "ignores health questions outside of the scoped collection" do
      create :health_question

      hq1.update! next_question: hq2
      hq2.update! next_question: hq3

      expect(
        vaccine
          .health_questions
          .where(id: [hq1.id, hq2.id, hq3.id])
          .first_health_question
      ).to eq(hq1)
    end
  end

  describe ".last_health_question" do
    let!(:hq1) { create :health_question, vaccine: }
    let!(:hq2) { create :health_question, vaccine: }
    let!(:hq3) { create :health_question, vaccine: }

    it "returns the last health question" do
      hq1.update! next_question: hq2
      hq2.update! next_question: hq3

      expect(vaccine.health_questions.last_health_question).to eq(hq3)
    end

    it "ignores health questions outside of the scoped collection" do
      create :health_question

      hq1.update! next_question: hq2
      hq2.update! next_question: hq3

      expect(
        vaccine
          .health_questions
          .where(id: [hq1.id, hq2.id, hq3.id])
          .last_health_question
      ).to eq(hq3)
    end
  end

  describe "#remaining_questions" do
    let(:hq1) { create :health_question, vaccine: }
    let(:hq2) { create :health_question, vaccine: }
    let(:hq3) { create :health_question, vaccine: }

    it "returns remaining questions in order" do
      hq1.update! next_question: hq2
      hq2.update! next_question: hq3

      expect(hq1.remaining_questions).to eq([hq1, hq2, hq3])
    end

    it "orders follow up questions before next questions" do
      hq1.update! next_question: hq2, follow_up_question: hq3
      hq3.update! next_question: hq2

      expect(hq1.remaining_questions).to eq([hq1, hq3, hq2])
    end
  end
end
