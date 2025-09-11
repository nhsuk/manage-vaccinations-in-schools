# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id          :bigint           not null, primary key
#  archived_at :datetime
#  expiry      :date
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  team_id     :bigint
#  vaccine_id  :bigint           not null
#
# Indexes
#
#  index_batches_on_team_id_and_name_and_expiry_and_vaccine_id  (team_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_vaccine_id                                  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Batch < ApplicationRecord
  include Archivable

  audited associated_with: :vaccine

  belongs_to :team, optional: true
  belongs_to :vaccine

  has_and_belongs_to_many :immunisation_imports

  has_one :programme, through: :vaccine

  scope :order_by_name_and_expiration, -> { order(expiry: :asc, name: :asc) }

  scope :expired,
        -> { where(expiry: nil).or(where("expiry <= ?", Time.current)) }
  scope :not_expired,
        -> { where.not(expiry: nil).where("expiry > ?", Time.current) }

  NAME_FORMAT = /\A[A-Za-z0-9]+\z/

  validates :name,
            presence: true,
            format: {
              with: NAME_FORMAT
            },
            length: {
              minimum: 2,
              maximum: 100
            }

  validates :expiry,
            uniqueness: {
              scope: %i[team_id name vaccine_id],
              allow_nil: true
            }
end
