# frozen_string_literal: true

class ConsentGrouper
  def initialize(consents, programme:)
    @consents = consents
    @programme = programme
  end

  def call
    consents
      .select { it.programme_id == programme.id }
      .reject(&:invalidated?)
      .select { it.response_given? || it.response_refused? }
      .group_by(&:name)
      .map { it.second.max_by(&:created_at) }
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :consents, :programme
end
