# frozen_string_literal: true

class Programme
  include FlipperActor
  include GelatineVaccinesConcern

  TYPES = %w[flu hpv menacwy mmr td_ipv].freeze
  TYPES_SUPPORTING_DELEGATION = %w[flu].freeze

  attr_accessor :type

  def initialize(type:)
    @type = type
  end

  class InvalidType < StandardError
  end

  def self.method_missing(type, *_args) = find(type.to_s)

  def self.respond_to_missing?(type, *_args) = exists?(type.to_s)

  def self.all = TYPES.map { find(it) }

  def self.find(type)
    @programmes ||= {}
    @programmes[type] ||= if exists?(type)
      Programme.new(type:)
    else
      raise InvalidType, type
    end
  end

  def self.find_all(types) = types.map { find(it) }

  def self.exists?(type) = type.in?(TYPES)

  def self.sample = find(TYPES.sample)

  def to_param = type

  def id = type

  def ==(other) = type == other.type

  def eql?(other) = other.is_a?(Programme) && type.eql?(other.type)

  def <=>(other) = type <=> other.type

  delegate :hash, to: :type

  TYPES.each { |type| define_method("#{type}?") { self.type == type } }

  def name
    @name ||= I18n.t(type, scope: :programme_types)
  end

  def name_in_sentence
    @name_in_sentence ||= flu? ? name.downcase : name
  end

  def doubles? = menacwy? || td_ipv?

  def seasonal? = flu?

  def catch_up_only? = mmr?

  def supports_delegation? = TYPES_SUPPORTING_DELEGATION.include?(type)

  def can_save_to_todays_batch? = !mmr?

  def triage_on_vaccination_history? = menacwy? || td_ipv?

  DEFAULT_YEAR_GROUPS_BY_TYPE = {
    "flu" => (0..11).to_a,
    "hpv" => (8..11).to_a,
    "menacwy" => (9..11).to_a,
    "mmr" => (0..11).to_a,
    "td_ipv" => (9..11).to_a
  }.freeze

  def default_year_groups
    DEFAULT_YEAR_GROUPS_BY_TYPE.fetch(type)
  end

  def is_catch_up?(year_group:)
    return nil if seasonal?
    return true if catch_up_only?

    # NOTE: This logic only works if no teams administer programmes to year
    #  groups earlier than the first default year group for that programme.
    #  We only know of teams administering beyond the default year groups.
    default_year_groups.first != year_group
  end

  def vaccines
    @vaccines ||= Vaccine.where_programme(self)
  end

  def vaccine_methods
    @vaccine_methods ||= vaccines.map(&:method).uniq
  end

  def has_multiple_vaccine_methods?
    @has_multiple_vaccine_methods ||= vaccine_methods.length > 1
  end

  def available_delivery_methods
    @available_delivery_methods ||=
      vaccines.flat_map(&:available_delivery_methods).uniq
  end

  def available_delivery_sites
    @available_delivery_sites ||=
      vaccines.flat_map(&:available_delivery_sites).uniq
  end

  def default_dose_sequence = hpv? || flu? ? 1 : nil

  MAXIMUM_DOSE_SEQUENCES = {
    "flu" => 2,
    "hpv" => 3,
    "menacwy" => 3,
    "mmr" => 2,
    "td_ipv" => 5
  }.freeze

  def maximum_dose_sequence
    MAXIMUM_DOSE_SEQUENCES.fetch(type)
  end

  IMPORT_NAMES = {
    "flu" => %w[Flu],
    "hpv" => %w[HPV],
    "menacwy" => %w[ACWYX4 MenACWY],
    "mmr" => %w[MMR],
    "td_ipv" => %w[3-in-1 Td/IPV]
  }.freeze

  def import_names
    IMPORT_NAMES.fetch(type)
  end

  SNOMED_TARGET_DISEASE_CODES = {
    "hpv" => %w[240532009].to_set,
    "flu" => %w[6142004].to_set,
    "menacwy" => %w[23511006].to_set,
    "mmr" => %w[14189004 36989005 36653000].to_set,
    "td_ipv" => %w[76902006 397430003 398102009].to_set
  }.freeze

  def snomed_target_disease_codes
    SNOMED_TARGET_DISEASE_CODES.fetch(type)
  end

  SNOMED_TARGET_DISEASE_TERMS = {
    "hpv" => ["Human papillomavirus infection"],
    "flu" => ["Influenza"],
    "menacwy" => ["Meningococcal infectious disease"],
    "mmr" => %w[Measles Mumps Rubella],
    "td_ipv" => [
      "Tetanus",
      "Diphtheria caused by Corynebacterium diphtheriae",
      "Acute poliomyelitis"
    ]
  }.freeze

  def snomed_target_disease_terms
    SNOMED_TARGET_DISEASE_TERMS.fetch(type)
  end

  SNOMED_TARGET_DISEASE_NAMES = {
    "flu" => "FLU",
    "hpv" => "HPV",
    "menacwy" => "MENACWY",
    "mmr" => "MMR",
    "td_ipv" => "3IN1"
  }.freeze

  def snomed_target_disease_name
    SNOMED_TARGET_DISEASE_NAMES.fetch(type)
  end

  delegate :fhir_target_disease_coding, to: :fhir_mapper

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Programme.new(self)
  end
end
