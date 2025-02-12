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

  has_many :cohort_imports
  has_many :consent_forms
  has_many :consent_notifications
  has_many :consents
  has_many :dps_exports
  has_many :immunisation_imports
  has_many :organisation_programmes
  has_many :triages
  has_many :vaccination_records, -> { kept }
  has_many :vaccines

  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions
  has_many :organisations, through: :organisation_programmes

  has_many :active_vaccines, -> { active }, class_name: "Vaccine"

  enum :type, { flu: "flu", hpv: "hpv" }, validate: true

  def name
    human_enum_name(:type)
  end

  YEAR_GROUPS_BY_TYPE = { "flu" => (0..11).to_a, "hpv" => (8..11).to_a }.freeze

  def year_groups
    YEAR_GROUPS_BY_TYPE.fetch(type)
  end

  def birth_academic_years
    year_groups.map(&:to_birth_academic_year)
  end

  def to_param
    type
  end

  SNOMED_PROCEDURE_CODES = {
    "hpv" => "761841000",
    "flu" => "822851000000102"
  }.freeze

  def snomed_procedure_code
    SNOMED_PROCEDURE_CODES.fetch(type)
  end

  SNOMED_PROCEDURE_TERMS = {
    "hpv" =>
      "Administration of vaccine product containing only Human papillomavirus antigen (procedure)",
    "flu" => "Seasonal influenza vaccination (procedure)"
  }.freeze

  def snomed_procedure_term
    SNOMED_PROCEDURE_TERMS.fetch(type)
  end
end
