# frozen_string_literal: true

module BelongsToAcademicYear
  extend ActiveSupport::Concern

  class_methods do
    def academic_year_attribute(name = nil)
      @academic_year_attribute = name if name
      @academic_year_attribute
    end
  end

  included do
    scope :for_academic_year,
          ->(academic_year) do
            where(
              academic_year_attribute =>
                academic_year.to_academic_year_date_range
            )
          end

    def academic_year
      __send__(self.class.academic_year_attribute).to_date.academic_year
    end
  end
end
