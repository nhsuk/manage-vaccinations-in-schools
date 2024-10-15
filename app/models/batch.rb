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
#  team_id    :bigint           not null
#  vaccine_id :bigint           not null
#
# Indexes
#
#  index_batches_on_team_id                                     (team_id)
#  index_batches_on_team_id_and_name_and_expiry_and_vaccine_id  (team_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_vaccine_id                                  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Batch < ApplicationRecord
  audited

  belongs_to :team
  belongs_to :vaccine

  scope :order_by_name_and_expiration, -> { order(expiry: :asc, name: :asc) }

  has_many :vaccination_records

  has_and_belongs_to_many :immunisation_imports

  validates :name, presence: true, format: { with: /\A[A-Za-z0-9]+\z/ }

  validates :expiry,
            presence: true,
            comparison: {
              greater_than: -> { Date.new(Date.current.year - 15, 1, 1) },
              less_than: -> { Date.new(Date.current.year + 15, 1, 1) }
            }
end
