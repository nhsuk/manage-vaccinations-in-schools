# frozen_string_literal: true

class Programme
  include FlipperActor
  include GelatineVaccinesConcern

  class InvalidType < StandardError
  end

  TYPES = %w[flu hpv menacwy mmr td_ipv].freeze
  TYPES_SUPPORTING_DELEGATION = %w[flu].freeze
  MIN_MMRV_ELIGIBILITY_DATE = Date.new(2020, 1, 1).freeze

  DISEASE_TYPES = {
    "flu" => %w[influenza],
    "hpv" => %w[human_papillomavirus],
    "mmr" => %w[measles mumps rubella],
    "td_ipv" => %w[tetanus diphtheria polio],
    "menacwy" => %w[meningitis_a meningitis_c meningitis_w meningitis_y]
  }.freeze

  DEFAULT_YEAR_GROUPS_BY_TYPE = {
    "flu" => (0..11).to_a,
    "hpv" => (8..11).to_a,
    "menacwy" => (9..11).to_a,
    "mmr" => (0..11).to_a,
    "td_ipv" => (9..11).to_a
  }.freeze

  MAXIMUM_DOSE_SEQUENCES = {
    "flu" => 2,
    "hpv" => 3,
    "menacwy" => 3,
    "mmr" => 2,
    "td_ipv" => 5
  }.freeze

  IMPORT_NAMES = {
    "flu" => %w[Flu],
    "hpv" => %w[HPV],
    "menacwy" => %w[ACWYX4 MenACWY],
    "mmr" => %w[MMR],
    "td_ipv" => %w[3-in-1 Td/IPV]
  }.freeze

  SNOMED_TARGET_DISEASE_CODES = {
    "hpv" => %w[240532009].to_set,
    "flu" => %w[6142004].to_set,
    "menacwy" => %w[23511006].to_set,
    "mmr" => %w[14189004 36989005 36653000].to_set,
    "td_ipv" => %w[76902006 397430003 398102009].to_set
  }.freeze

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

  SNOMED_TARGET_DISEASE_NAMES = {
    "flu" => "FLU",
    "hpv" => "HPV",
    "menacwy" => "MENACWY",
    "mmr" => "MMR",
    "td_ipv" => "3IN1"
  }.freeze

  SNOMED_PROCEDURE_TERMS = {
    "flu" => "Seasonal influenza vaccination (procedure)",
    "hpv" =>
      "Administration of vaccine product containing only Human " \
        "papillomavirus antigen (procedure)",
    "menacwy" =>
      "Administration of vaccine product containing only Neisseria " \
        "meningitidis serogroup A, C, W135 and Y antigens (procedure)",
    "mmr" =>
      "Administration of vaccine product containing only Measles " \
        "morbillivirus and Mumps orthorubulavirus and Rubella virus " \
        "antigens (procedure)",
    "td_ipv" =>
      "Administration of vaccine product containing only Clostridium " \
        "tetani and Corynebacterium diphtheriae and Human poliovirus " \
        "antigens (procedure)"
  }.freeze

  attr_reader :type

  delegate :hash, to: :type

  class << self
    def method_missing(type, *_args) = find(type.to_s)

    def respond_to_missing?(type, *_args) = exists?(type.to_s)

    def all = TYPES.map { |type| find(type) }

    def find_all(types, patient: nil, disease_types: nil, academic_year: nil)
      types.map { |type| find(type, patient:, disease_types:, academic_year:) }
    end

    def find(type, disease_types: nil, patient: nil, academic_year: nil)
      validate_type!(type)

      @programmes ||= {}
      programme = (@programmes[type] ||= new(type:))

      if disease_types.nil? && patient && academic_year && programme.mmr? &&
           Flipper.enabled?(:mmrv)
        # TODO: Find a way of removing this logic, instead we should pass the
        #  disease types in directly.

        # It's possible that an MMRV eligible patient ended up getting just the
        # MMR vaccine because there was no MMRV stock available. Therefore, we
        # need to check the programme status first to see if it has MMR disease
        # types.

        programme_status = patient.programme_status(programme, academic_year:)
        disease_types ||= programme_status.disease_types
      end

      programme.variant_for(patient:, disease_types:)
    end

    def exists?(type) = type.in?(TYPES)

    def sample = find(TYPES.sample)

    private

    def validate_type!(type)
      raise InvalidType, type unless exists?(type)
    end
  end

  def initialize(type:)
    @type = type
  end

  def to_param = type

  def id = type

  def ==(other) = type == other.type

  def eql?(other) = other.is_a?(Programme) && type.eql?(other.type)

  def <=>(other) = type <=> other.type

  def translation_key = type

  TYPES.each do |programme_type|
    define_method("#{programme_type}?") { type == programme_type }
  end

  def name
    @name ||= I18n.t(type, scope: :programme_types)
  end

  def name_in_sentence
    @name_in_sentence ||= flu? ? name.downcase : name
  end

  def filter_name = Flipper.enabled?(:mmrv) && mmr? ? "MMR(V)" : name

  def variant_for(disease_types: nil, patient: nil)
    return self unless mmr?

    unless disease_types&.include?("varicella") || patient&.eligible_for_mmrv?
      return self
    end

    if Flipper.enabled?(:mmrv)
      ProgrammeVariant.new(self, variant_type: "mmrv")
    else
      self
    end
  end

  def disease_types = DISEASE_TYPES.fetch(type)

  def doubles? = menacwy? || td_ipv?

  def seasonal? = flu?

  def catch_up_only? = mmr?

  def supports_delegation? = TYPES_SUPPORTING_DELEGATION.include?(type)

  def can_save_to_todays_batch? = !mmr?

  def triage_on_vaccination_history? = menacwy? || td_ipv?

  def default_year_groups = DEFAULT_YEAR_GROUPS_BY_TYPE.fetch(type)

  def is_catch_up?(year_group:)
    return nil if seasonal?
    return true if catch_up_only?

    # NOTE: This logic only works if no teams administer programmes to year
    # groups earlier than the first default year group for that programme.
    # We only know of teams administering beyond the default year groups.
    default_year_groups.first != year_group
  end

  def vaccines
    @vaccines ||= Vaccine.for_programme(self)
  end

  def vaccine_methods
    @vaccine_methods ||= vaccines.map(&:method).uniq
  end

  def has_multiple_vaccine_methods? = vaccine_methods.length > 1

  def available_delivery_methods
    @available_delivery_methods ||=
      vaccines.flat_map(&:available_delivery_methods).uniq
  end

  def available_delivery_sites
    @available_delivery_sites ||=
      vaccines.flat_map(&:available_delivery_sites).uniq
  end

  def default_dose_sequence = hpv? || flu? ? 1 : nil

  def maximum_dose_sequence = MAXIMUM_DOSE_SEQUENCES.fetch(type)

  def import_names = IMPORT_NAMES.fetch(type)

  def snomed_target_disease_codes = SNOMED_TARGET_DISEASE_CODES.fetch(type)

  def snomed_target_disease_terms = SNOMED_TARGET_DISEASE_TERMS.fetch(type)

  def snomed_target_disease_name = SNOMED_TARGET_DISEASE_NAMES.fetch(type)

  def snomed_procedure_term = SNOMED_PROCEDURE_TERMS.fetch(type)

  delegate :fhir_target_disease_coding, to: :fhir_mapper

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Programme.new(self)
  end
end
