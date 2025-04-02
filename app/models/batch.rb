# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id              :bigint           not null, primary key
#  archived_at     :datetime
#  expiry          :date
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint           not null
#  vaccine_id      :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_name_expiry_vaccine_id_6d9ae30338  (organisation_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_vaccine_id                               (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Batch < ApplicationRecord
  include Archivable

  audited associated_with: :vaccine

  belongs_to :organisation
  belongs_to :vaccine

  has_and_belongs_to_many :immunisation_imports

  has_one :programme, through: :vaccine

  scope :order_by_name_and_expiration, -> { order(expiry: :asc, name: :asc) }

  scope :expired, -> { where("expiry <= ?", Time.current) }
  scope :not_expired, -> { where("expiry > ?", Time.current) }

  validates :name, presence: true, format: { with: /\A[A-Za-z0-9]+\z/ }

  validates :expiry,
            uniqueness: {
              scope: %i[organisation_id name vaccine_id],
              allow_nil: true
            }
end
