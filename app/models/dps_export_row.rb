# frozen_string_literal: true

class DPSExportRow
  FIELDS = %i[date_and_time].freeze

  attr_reader :vaccination

  def initialize(vaccination)
    @vaccination = vaccination
  end

  def to_a
    FIELDS.map { send _1 }
  end

  def date_and_time
    vaccination.recorded_at
  end
end
