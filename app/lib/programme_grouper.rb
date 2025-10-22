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

  def programme(object) = object.try(:programme) || object

  def group(object) = programme(object).group

  def type(object) = programme(object).type

  def sorted(objects) = objects.sort_by { type(it) }
end
