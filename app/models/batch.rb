# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id         :bigint           not null, primary key
#  expiry     :date             not null
#  name       :string           not null
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
  audited

  belongs_to :vaccine

  has_many :vaccination_records

  has_and_belongs_to_many :immunisation_imports

  has_many :programmes, through: :vaccine

  validates :name, presence: true
  validates :expiry, presence: true
end
