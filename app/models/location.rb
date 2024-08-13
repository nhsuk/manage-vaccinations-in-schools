# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address          :text
#  county           :text
#  locality         :text
#  name             :text             not null
#  postcode         :text
#  town             :text
#  type             :integer          not null
#  url              :text
#  urn              :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  imported_from_id :bigint
#
# Indexes
#
#  index_locations_on_imported_from_id  (imported_from_id)
#  index_locations_on_urn               (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#
class Location < ApplicationRecord
  self.inheritance_column = :nil

  audited

  has_many :sessions
  has_many :patients, foreign_key: :school_id
  has_many :consent_forms, through: :sessions
  belongs_to :imported_from, class_name: "ImmunisationImport", optional: true

  enum :type, %w[school generic_clinic]

  validates :name, presence: true

  validates :urn, presence: true, if: :school?
  validates :urn, uniqueness: true, allow_nil: true
end
