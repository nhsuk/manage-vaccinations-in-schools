# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id              :bigint           not null, primary key
#  archived_at     :datetime
#  expiry          :date             not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint           not null
#  vaccine_id      :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_name_expiry_vaccine_id_6d9ae30338  (organisation_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_organisation_id                          (organisation_id)
#  index_batches_on_vaccine_id                               (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class Batch < ApplicationRecord
  audited

  belongs_to :organisation
  belongs_to :vaccine

  scope :order_by_name_and_expiration, -> { order(expiry: :asc, name: :asc) }

  scope :archived, -> { where.not(archived_at: nil) }
  scope :unarchived, -> { where(archived_at: nil) }

  has_many :vaccination_records

  has_and_belongs_to_many :immunisation_imports

  validates :name, presence: true, format: { with: /\A[A-Za-z0-9]+\z/ }

  validates :expiry,
            presence: true,
            comparison: {
              greater_than: -> { Date.new(Date.current.year - 15, 1, 1) },
              less_than: -> { Date.new(Date.current.year + 15, 1, 1) }
            },
            uniqueness: {
              scope: %i[organisation_id name vaccine_id]
            }

  def archived?
    archived_at != nil
  end

  def unarchived?
    archived_at.nil?
  end

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  def unarchive!
    update!(archived_at: nil) if archived?
  end
end
