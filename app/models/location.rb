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

  self.inheritance_column = :nil

  audited

  belongs_to :team, optional: true

  has_many :sessions
  has_many :patients, foreign_key: :school_id
  has_many :consent_forms, through: :sessions

  has_and_belongs_to_many :immunisation_imports

  enum :type, %w[school generic_clinic]

  validates :name, presence: true
  validates :url, url: true, allow_nil: true

  validates :ods_code, presence: true, if: :generic_clinic?
  validates :ods_code, uniqueness: true, allow_nil: true

  validates :urn, presence: true, if: :school?
  validates :urn, uniqueness: true, allow_nil: true
end
