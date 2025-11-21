# frozen_string_literal: true

class ProgrammeVariant < SimpleDelegator
  attr_reader :variant_type

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
end
