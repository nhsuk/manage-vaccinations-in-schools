# frozen_string_literal: true

class ConsentGrouper
  def initialize(consents, programme_type:, academic_year:)
    @consents = consents
    @programme_type = programme_type
    @academic_year = academic_year
  end

  def call
    if consents.is_a?(Array) || consents.loaded?
      consents
        .select { it.programme_type == programme_type }
        .select { it.academic_year == academic_year }
        .reject(&:invalidated?)
        .select(&:response_provided?)
        .group_by(&:name)
        .map { it.second.max_by(&:submitted_at) }
    else
      consents
        .where(programme_type:, academic_year:)
        .not_invalidated
        .response_provided
        .includes(:parent)
        .group_by(&:name)
        .map { it.second.max_by(&:submitted_at) }
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :consents, :programme_type, :academic_year
end
