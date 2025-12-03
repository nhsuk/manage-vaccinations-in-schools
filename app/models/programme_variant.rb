# frozen_string_literal: true

class ProgrammeVariant < SimpleDelegator
  attr_reader :variant_type

  DISTINGUISHING_DISEASE_TYPES = {
    "mmrv" => ["varicella"] # MMR + Varicella = MMRV
  }.freeze

  SNOMED_PROCEDURE_TERMS = { "mmrv" => "TBC" }.freeze

  def initialize(programme, variant_type:)
    super(programme)
    @variant_type = variant_type
  end

  def translation_key = variant_type

  def name
    @name ||= I18n.t(variant_type, scope: :programme_types)
  end

  def name_in_sentence
    @name_in_sentence ||= flu? ? name.downcase : name
  end

  def vaccines
    @vaccines ||=
      Vaccine.where_programme(self, DISTINGUISHING_DISEASE_TYPES[variant_type])
  end

  def snomed_procedure_term
    SNOMED_PROCEDURE_TERMS.fetch(variant_type)
  end
end
