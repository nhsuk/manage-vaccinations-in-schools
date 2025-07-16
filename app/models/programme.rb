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
  include GelatineVaccinesConcern

  self.inheritance_column = nil

  audited
  has_associated_audits

  has_many :consent_forms
  has_many :consent_notification_programmes
  has_many :consents
  has_many :gillick_assessments
  has_many :immunisation_imports
  has_many :organisation_programmes
  has_many :pre_screenings
  has_many :session_programmes
  has_many :triages
  has_many :vaccination_records, -> { kept }
  has_many :vaccines

  has_many :consent_notifications, through: :consent_notification_programmes
  has_many :sessions, through: :session_programmes
  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions
  has_many :organisations, through: :organisation_programmes

  has_many :active_vaccines, -> { active }, class_name: "Vaccine"

  enum :type,
       { flu: "flu", hpv: "hpv", menacwy: "menacwy", td_ipv: "td_ipv" },
       validate: true

  delegate :fhir_target_disease_coding, :fhir_procedure_coding, to: :fhir_mapper

  def to_param = type

  def name = human_enum_name(:type)

  def name_in_sentence = flu? ? name.downcase : name

  def doubles? = menacwy? || td_ipv?

  def seasonal? = flu?

  DEFAULT_YEAR_GROUPS_BY_TYPE = {
    "flu" => (0..11).to_a,
    "hpv" => (8..11).to_a,
    "menacwy" => (9..11).to_a,
    "td_ipv" => (9..11).to_a
  }.freeze

  def default_year_groups
    DEFAULT_YEAR_GROUPS_BY_TYPE.fetch(type)
  end

  alias_method :year_groups, :default_year_groups

  def birth_academic_years
    year_groups.map(&:to_birth_academic_year)
  end

  def vaccine_methods = vaccines.map(&:method).uniq

  def has_multiple_vaccine_methods?
    # TODO: Ideally this would work as below, however that doesn't work well
    #  in a list as it results in N+1 issues, without deeply pre-fetching
    #  the vaccines which is a lot of data.

    # vaccine_methods.length > 1

    flu?
  end

  def available_delivery_methods
    vaccines.flat_map(&:available_delivery_methods).uniq
  end

  def available_delivery_sites
    vaccines.flat_map(&:available_delivery_sites).uniq
  end

  DOSE_SEQUENCES = {
    "flu" => 1,
    "hpv" => 1,
    "menacwy" => 1,
    "td_ipv" => 5
  }.freeze

  def vaccinated_dose_sequence
    DOSE_SEQUENCES.fetch(type)
  end

  def default_dose_sequence
    hpv? || flu? ? vaccinated_dose_sequence : nil
  end

  def maximum_dose_sequence
    # HPV is given 3 times to patients with a weakened immune system.
    # MenACWY is sometimes given more frequently.
    hpv? || menacwy? ? 3 : vaccinated_dose_sequence
  end

  IMPORT_NAMES = {
    "flu" => %w[Flu],
    "hpv" => %w[HPV],
    "menacwy" => %w[ACWYX4 MenACWY],
    "td_ipv" => %w[3-in-1 Td/IPV]
  }.freeze

  def import_names
    IMPORT_NAMES.fetch(type)
  end

  SNOMED_PROCEDURE_CODES = {
    "flu" => "822851000000102",
    "hpv" => "761841000",
    "menacwy" => "871874000",
    "td_ipv" => "866186002"
  }.freeze

  def snomed_procedure_code
    SNOMED_PROCEDURE_CODES.fetch(type)
  end

  SNOMED_PROCEDURE_TERMS = {
    "flu" => "Seasonal influenza vaccination (procedure)",
    "hpv" =>
      "Administration of vaccine product containing only Human " \
        "papillomavirus antigen (procedure)",
    "menacwy" =>
      "Administration of vaccine product containing only Neisseria " \
        "meningitidis serogroup A, C, W135 and Y antigens (procedure)",
    "td_ipv" =>
      "Administration of vaccine product containing only Clostridium " \
        "tetani and Corynebacterium diphtheriae and Human poliovirus " \
        "antigens (procedure)"
  }.freeze

  def snomed_procedure_term
    SNOMED_PROCEDURE_TERMS.fetch(type)
  end

  SNOMED_TARGET_DISEASE_CODES = {
    "hpv" => "240532009",
    "flu" => "6142004"
  }.freeze

  def snomed_target_disease_code
    SNOMED_TARGET_DISEASE_CODES.fetch(type)
  end

  SNOMED_TARGET_DISEASE_TERMS = {
    "hpv" => "Human papillomavirus infection",
    "flu" => "Influenza"
  }.freeze

  def snomed_target_disease_term
    SNOMED_TARGET_DISEASE_TERMS.fetch(type)
  end

  private

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::Programme.new(self)
end
