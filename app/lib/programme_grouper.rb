# frozen_string_literal: true

class ProgrammeGrouper
  def initialize(programmes)
    @programmes = programmes
  end

  def call
    programmes
      .group_by { programme_group(it) }
      .transform_values { it.sort_by(&:type) }
      .to_h
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :programmes

  def programme_group(programme)
    if programme.flu?
      :flu
    elsif programme.hpv?
      :hpv
    elsif programme.td_ipv? || programme.menacwy?
      :doubles # Td/IPV and MenACWY is administered together
    else
      raise "Unknown programme type #{programme.type}"
    end
  end
end
