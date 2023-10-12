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
  belongs_to :vaccine
end
