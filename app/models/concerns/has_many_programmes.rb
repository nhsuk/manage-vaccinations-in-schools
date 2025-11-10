# frozen_string_literal: true

module HasManyProgrammes
  extend ActiveSupport::Concern

  included { after_validation :set_programme_types }

  def set_programme_types
    self.programme_types = programmes.map(&:type).sort
  end

  def vaccines
    @vaccines ||=
      Vaccine.includes(:programme).where(programme_type: programme_types)
  end
end
