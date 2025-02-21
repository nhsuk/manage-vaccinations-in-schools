# frozen_string_literal: true

class ProgrammeGrouper
  def initialize(programmes)
    @programmes = programmes
  end

  def call
    programmes.group_by { programme_group(it) }.map(&:second)
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :programmes

  def programme_group(programme)
    if programme.hpv?
      0
    elsif programme.td_ipv? || programme.menacwy?
      1 # Td/IPV and MenACWY is administered together ("doubles")
    else
      raise "Unknown programme type #{programme.type}"
    end
  end
end
