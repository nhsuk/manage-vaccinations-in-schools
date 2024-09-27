# frozen_string_literal: true

# == Schema Information
#
# Table name: programmes
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_programmes_on_type  (type) UNIQUE
#
class Programme < ApplicationRecord
  self.inheritance_column = nil

  audited

  has_and_belongs_to_many :sessions

  has_many :consent_forms
  has_many :consents
  has_many :dps_exports
  has_many :immunisation_imports
  has_many :team_programmes
  has_many :triages
  has_many :vaccination_records
  has_many :vaccines

  has_many :batches, through: :vaccines
  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions
  has_many :teams, through: :team_programmes

  enum :type, { flu: "flu", hpv: "hpv" }, validate: true

  def name
    human_enum_name(:type)
  end

  YEAR_GROUPS_BY_TYPE = { "flu" => (0..11).to_a, "hpv" => (8..11).to_a }.freeze

  def year_groups
    YEAR_GROUPS_BY_TYPE.fetch(type)
  end
end
