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

RSpec.describe HealthQuestion do
  describe ".first_health_question" do
    let(:vaccine) { create :vaccine, type: "tester" }
    let!(:hq1) { create :health_question, vaccine: }
    let!(:hq2) { create :health_question, vaccine: }
    let!(:hq3) { create :health_question, vaccine: }

    it "returns the first health question" do
      hq1.update! next_question: hq2.id
      hq2.update! next_question: hq3.id

      expect(vaccine.health_questions.first_health_question).to eq(hq1)
    end

    it "raises an error if there is no first question" do
      hq1.update! next_question: hq2.id
      hq2.update! next_question: hq3.id
      hq3.update! next_question: hq1.id

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "No first question found"
      )
    end

    it "raises an error if there is more than one first question" do
      hq2.update! next_question: hq3.id

      expect { vaccine.health_questions.first_health_question }.to raise_error(
        "More than one first question found"
      )
    end

    it "ignores health questions outside of the scoped collection" do
      create :health_question

      hq1.update! next_question: hq2.id
      hq2.update! next_question: hq3.id

      expect(
        vaccine
          .health_questions
          .where(id: [hq1.id, hq2.id, hq3.id])
          .first_health_question
      ).to eq(hq1)
    end
  end
end
