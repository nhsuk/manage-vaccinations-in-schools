# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id                        :bigint           not null, primary key
#  address_line_1            :text
#  address_line_2            :text
#  address_postcode          :text
#  address_town              :text
#  gias_establishment_number :integer
#  gias_local_authority_code :integer
#  name                      :text             not null
#  ods_code                  :string
#  status                    :integer          default("unknown"), not null
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  year_groups               :integer          default([]), not null, is an Array
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  team_id                   :bigint
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_team_id   (team_id)
#  index_locations_on_urn       (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Location < ApplicationRecord
  include AddressConcern
  include ODSCodeConcern

  self.inheritance_column = :nil

  audited associated_with: :team
  has_associated_audits

  belongs_to :team, optional: true

  has_many :consent_forms
  has_many :patients, foreign_key: :school_id
  has_many :sessions

  has_one :organisation, through: :team

  # This is based on the school statuses from the DfE GIAS data.
  enum :status,
       { unknown: 0, open: 1, closed: 2, opening: 3, closing: 4 },
       default: :unknown

  enum :type,
       { school: 0, generic_clinic: 1, community_clinic: 2, gp_practice: 3 }

  scope :clinic, -> { generic_clinic.or(community_clinic) }

  validates :name, presence: true
  validates :url, url: true, allow_nil: true
  validates :urn, uniqueness: true, allow_nil: true

  with_options if: :clinic? do
    validates :team, presence: true
  end

  with_options if: :community_clinic? do
    validates :ods_code, exclusion: { in: :organisation_ods_code }
  end

  with_options if: :generic_clinic? do
    validates :ods_code, inclusion: { in: :organisation_ods_code }
  end

  with_options if: :gp_practice? do
    validates :ods_code, presence: true
  end

  with_options if: :school? do
    validates :gias_establishment_number, presence: true
    validates :gias_local_authority_code, presence: true
    validates :urn, presence: true
  end

  normalizes :urn, with: -> { _1.blank? ? nil : _1.strip }

  def clinic?
    generic_clinic? || community_clinic?
  end

  def dfe_number
    "#{gias_local_authority_code}#{gias_establishment_number}" if school?
  end

  private

  def organisation_ods_code
    [team&.organisation&.ods_code]
  end
end
