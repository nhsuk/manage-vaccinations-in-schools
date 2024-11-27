# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address_line_1   :text
#  address_line_2   :text
#  address_postcode :text
#  address_town     :text
#  name             :text             not null
#  ods_code         :string
#  type             :integer          not null
#  url              :text
#  urn              :string
#  year_groups      :integer          default([]), not null, is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  team_id          :bigint
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

  audited

  belongs_to :team, optional: true

  has_many :consent_forms
  has_many :patients, foreign_key: :school_id
  has_many :sessions

  has_one :organisation, through: :team

  enum :type, { school: 0, generic_clinic: 1, community_clinic: 2 }

  scope :clinic, -> { generic_clinic.or(community_clinic) }

  scope :for_year_groups,
        ->(year_groups) do
          where("year_groups && ARRAY[?]::integer[]", year_groups)
        end

  validates :name, presence: true
  validates :url, url: true, allow_nil: true
  validates :urn, uniqueness: true, allow_nil: true

  with_options if: :clinic? do
    validates :ods_code, presence: true
    validates :team, presence: true
  end

  validates :ods_code,
            comparison: {
              equal_to: :organisation_ods_code
            },
            if: :generic_clinic?

  validates :urn, presence: true, if: :school?

  normalizes :urn, with: -> { _1.blank? ? nil : _1.strip }

  def clinic?
    generic_clinic? || community_clinic?
  end

  def school_moves_to_this_location
    school? ? SchoolMove.where(school: self) : SchoolMove.where(organisation:)
  end

  def school_moves_from_this_location
    patients =
      if school?
        Patient.where(school: self)
      else
        Patient.in_organisation(organisation)
      end

    SchoolMove.where(patient: patients)
  end

  def has_movers?
    school_moves_to_this_location.any? || school_moves_from_this_location.any?
  end

  private

  def organisation_ods_code
    team&.organisation&.ods_code
  end
end
