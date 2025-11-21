# frozen_string_literal: true

class ProgrammeGrouper
  def initialize(objects)
    @objects = objects
  end

  def call
    objects.group_by { group(it) }.transform_values { sorted(it) }.to_h
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :objects

  GROUPS = {
    "flu" => :flu,
    "hpv" => :hpv,
    "menacwy" => :doubles,
    "mmr" => :mmr,
    "td_ipv" => :doubles
  }.freeze

  def group(object)
    key = type(object)
    if (value = GROUPS[key])
      value
    else
      raise UnsupportedProgramme, programme(object)
    end
  end

  def sorted(objects) = objects.sort_by { type(it) }

  def type(object) = object.try(:programme_type) || programme(object).type

  def programme(object) = object.try(:programme) || object
end
