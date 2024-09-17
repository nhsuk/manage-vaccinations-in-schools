# frozen_string_literal: true

module CohortsHelper
  def format_year_group(year_group)
    if year_group.negative?
      "Nursery"
    elsif year_group.zero?
      "Reception"
    else
      "Year #{year_group}"
    end
  end
end
