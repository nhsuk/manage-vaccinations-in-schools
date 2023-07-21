# == Schema Information
#
# Table name: batches
#
#  id         :bigint           not null, primary key
#  expiry     :date
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_batches_on_vaccine_id  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Batch < ApplicationRecord
  belongs_to :vaccine

  validates :name, presence: true
  validates :expiry, presence: true
end
