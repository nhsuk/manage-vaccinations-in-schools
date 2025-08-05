# frozen_string_literal: true

class UnsupportedProgramme < RuntimeError
  def initialize(programme)
    super("Unsupported programme: #{programme.name}")
  end
end
