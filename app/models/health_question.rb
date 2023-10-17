# == Schema Information
#
# Table name: health_questions
#
#  id         :bigint           not null, primary key
#  hint       :string
#  metadata   :jsonb            not null
#  question   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_health_questions_on_vaccine_id  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class HealthQuestion < ApplicationRecord
  attr_accessor :response, :notes
  jsonb_accessor :metadata, next_question: :string

  belongs_to :vaccine

  def self.first_health_question
    id_set = ids - all.pluck(Arel.sql("metadata->>'next_question'")).map(&:to_i)

    raise "No first question found" if id_set.empty?
    raise "More than one first question found" if id_set.length > 1

    find id_set.first
  end
end
