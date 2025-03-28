# frozen_string_literal: true

class ConsentGrouper
  def initialize(consents, programme: nil, programme_id: nil)
    @consents = consents
    @programme_id = programme_id || programme&.id

    raise "Provide a programme or programme id." if @programme_id.nil?
  end

  def call
    consents
      .select { it.programme_id == programme_id }
      .reject(&:invalidated?)
      .select(&:response_provided?)
      .group_by(&:name)
      .map { it.second.max_by(&:created_at) }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :consents, :programme_id
end
