# frozen_string_literal: true

module YearGroupConcern
  extend ActiveSupport::Concern

  def year_group
    birth_academic_year&.to_year_group
  end

  def year_group_changed?
    birth_academic_year_changed?
  end
end
