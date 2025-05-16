# frozen_string_literal: true

class ConsentGrouper
  def initialize(consents, programme: nil, programme_id: nil)
    @consents = consents
    @programme_id = programme_id || programme&.id

    raise "Provide a programme or programme id." if @programme_id.nil?
  end

  def call
    if consents.is_a?(Array) || consents.loaded?
      consents
        .select { it.programme_id == programme_id }
        .reject(&:invalidated?)
        .select(&:response_provided?)
        .group_by(&:name)
        .map { it.second.max_by(&:submitted_at) }
    else
      consents
        .where(programme_id:)
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

  attr_reader :consents, :programme_id
end
