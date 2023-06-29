# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_campaigns_on_vaccine_id  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Campaign < ApplicationRecord
  belongs_to :vaccine
  has_many :sessions, dependent: :destroy
  has_many :triage, dependent: :destroy
  has_many :consent_responses, dependent: :destroy

  validates :name, presence: true
end
