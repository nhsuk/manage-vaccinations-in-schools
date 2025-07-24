# frozen_string_literal: true

class TriageFinder
  def initialize(triages, programme_id:, academic_year:)
    @triages = triages
    @programme_id = programme_id
    @academic_year = academic_year
  end

  def call
    if triages.is_a?(Array) || triages.loaded?
      triages
        .select { it.programme_id == programme_id }
        .select { it.academic_year == academic_year }
        .reject(&:invalidated?)
        .max_by(&:created_at)
    else
      triages
        .where(programme_id:)
        .for_academic_year(academic_year)
        .not_invalidated
        .order(created_at: :desc)
        .first
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :triages, :programme_id, :academic_year
end
