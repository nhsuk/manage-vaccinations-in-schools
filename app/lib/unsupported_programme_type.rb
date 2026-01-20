# frozen_string_literal: true

class UnsupportedProgrammeType < StandardError
  def initialize(programme_type)
    super("Unsupported programme type: #{programme_type}")
  end
end
