# frozen_string_literal: true

class Programme::Variant < SimpleDelegator
  attr_reader :variant_type

  DISEASE_TYPES = {
    "mmr" => %w[measles mumps rubella],
    "mmrv" => %w[measles mumps rubella varicella]
  }.freeze

  IMPORT_NAMES = { "mmr" => %w[MMR], "mmrv" => %w[MMRV] }.freeze

  SNOMED_TARGET_DISEASE_CODES = {
    "mmr" => %w[14189004 36989005 36653000].to_set,
    "mmrv" => %w[14189004 36989005 36653000 38907003].to_set
  }.freeze

  SNOMED_TARGET_DISEASE_TERMS = {
    "mmr" => %w[Measles Mumps Rubella],
    "mmrv" => %w[Measles Mumps Rubella Varicella]
  }.freeze

  SNOMED_TARGET_DISEASE_NAMES = { "mmr" => "MMR", "mmrv" => "MMRV" }.freeze

  def initialize(programme, variant_type:)
    super(programme)
    @variant_type = variant_type
  end

  def mmr_variant? = variant_type == "mmr"

  def mmrv_variant? = variant_type == "mmrv"

  def translation_key = variant_type

  def name
    @name ||= I18n.t(translation_key, scope: :programme_types)
  end

  def name_in_sentence = name

  def disease_types = DISEASE_TYPES.fetch(variant_type)

  def import_names = IMPORT_NAMES.fetch(variant_type)

  def variants
    [self]
  end

  def vaccines
    @vaccines ||= Vaccine.for_programme(self)
  end

  def snomed_target_disease_codes
    SNOMED_TARGET_DISEASE_CODES.fetch(variant_type)
  end

  def snomed_target_disease_terms
    SNOMED_TARGET_DISEASE_TERMS.fetch(variant_type)
  end

  def snomed_target_disease_name
    SNOMED_TARGET_DISEASE_NAMES.fetch(variant_type)
  end

  def flipper_id
    "ProgrammeVariant:#{variant_type}"
  end

  delegate :fhir_target_disease_coding, to: :fhir_mapper

  private

  def fhir_mapper
    @fhir_mapper ||= FHIRMapper::Programme.new(self)
  end
end
