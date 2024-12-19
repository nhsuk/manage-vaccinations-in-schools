# frozen_string_literal: true

module YearGroupConcern
  extend ActiveSupport::Concern

  included do
    validates :birth_academic_year,
              comparison: {
                greater_than_or_equal_to: 1990
              }
  end

  def year_group
    return nil if birth_academic_year.nil?

    Date.new(birth_academic_year, 9, 1).year_group
  end
end
