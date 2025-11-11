# frozen_string_literal: true

class TriageFinder
  def initialize(triages, programme_type:, academic_year:)
    @triages = triages
    @programme_type = programme_type
    @academic_year = academic_year
  end

  def call
    if triages.is_a?(Array) || triages.loaded?
      triages
        .select { it.programme_type == programme_type }
        .select { it.academic_year == academic_year }
        .reject(&:invalidated?)
        .max_by(&:created_at)
    else
      triages
        .where(programme_type:, academic_year:)
        .not_invalidated
        .order(created_at: :desc)
        .first
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :triages, :programme_type, :academic_year
end
