# frozen_string_literal: true

class Programme::Variant < SimpleDelegator
  attr_reader :variant_type

  DISEASE_TYPES = {
    "mmr" => %w[measles mumps rubella],
    "mmrv" => %w[measles mumps rubella varicella]
  }.freeze

  IMPORT_NAMES = { "mmr" => %w[MMR], "mmrv" => %w[MMRV] }.freeze

  def initialize(programme, variant_type:)
    super(programme)
    @variant_type = variant_type
  end

  def translation_key = variant_type

  def name
    @name ||= I18n.t(translation_key, scope: :programme_types)
  end

  def name_in_sentence = name

  def disease_types = DISEASE_TYPES.fetch(variant_type)

  def import_names = IMPORT_NAMES.fetch(variant_type)

  def vaccines
    @vaccines ||= Vaccine.for_programme(self)
  end
end
