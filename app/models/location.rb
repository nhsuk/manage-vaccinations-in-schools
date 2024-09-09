# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  address    :text
#  county     :text
#  locality   :text
#  name       :text             not null
#  ods_code   :string
#  postcode   :text
#  town       :text
#  type       :integer          not null
#  url        :text
#  urn        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_urn       (urn) UNIQUE
#
class Location < ApplicationRecord
  self.inheritance_column = :nil

  audited

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
