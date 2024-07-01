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
  let!(:hqs) { create_list :health_question, 3, vaccine: }

  describe ".first_health_question" do
    it "returns the first health question" do
      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third

      expect(vaccine.health_questions.first_health_question).to eq(hqs.first)
    end

    it "raises an error if there is no first question" do
      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third
      hqs.third.update! next_question: hqs.first

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "No first question found"
      )
    end

    it "raises an error if there is more than one first question" do
      hqs.second.update! next_question: hqs.third

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "More than one first question found"
      )
    end

    it "ignores health questions outside of the scoped collection" do
      create :health_question

      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third

      expect(
        vaccine.health_questions.where(id: hqs.map(&:id)).first_health_question
      ).to eq(hqs.first)
    end
  end

  describe ".last_health_question" do
    it "returns the last health question" do
      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third

      expect(vaccine.health_questions.last_health_question).to eq(hqs.third)
    end

    it "ignores health questions outside of the scoped collection" do
      create :health_question

      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third

      expect(
        vaccine.health_questions.where(id: hqs.map(&:id)).last_health_question
      ).to eq(hqs.third)
    end
  end

  describe "#remaining_questions" do
    it "returns remaining questions in order" do
      hqs.first.update! next_question: hqs.second
      hqs.second.update! next_question: hqs.third

      expect(hqs.first.remaining_questions).to eq(
        [hqs.first, hqs.second, hqs.third]
      )
    end

    it "orders follow up questions before next questions" do
      hqs.first.update! next_question: hqs.second, follow_up_question: hqs.third
      hqs.third.update! next_question: hqs.second

      expect(hqs.first.remaining_questions).to eq(
        [hqs.first, hqs.third, hqs.second]
      )
    end
  end
end
