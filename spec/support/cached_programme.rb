# frozen_string_literal: true

class CachedProgramme
  def self.types
    @types ||= Programme.types.keys.map(&:to_sym)
  end

  def self.method_missing(programme_type, *_args)
    @cached_programmes ||= {}
    @cached_programmes[programme_type] ||= FactoryBot.create(
      :programme,
      programme_type
    )
  end

  def self.respond_to_missing?(programme_type, *_args)
    programme_type.in?(types)
  end

  def self.load! = types.each { send(it) }

  def self.sample = send(types.sample)
end
