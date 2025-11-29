# frozen_string_literal: true

module YearGroupsHelper
  def format_year_group(year_group)
    if year_group.negative?
      "Nursery"
    elsif year_group.zero?
      "Reception"
    else
      "Year #{year_group}"
    end
  end

  def format_year_groups(year_groups)
    if year_groups.empty?
      "No year groups"
    elsif year_groups.length == 1
      format_year_group(year_groups.first)
    else
      items = [
        ("Nursery" if year_groups.any?(&:negative?)),
        ("Reception" if year_groups.any?(&:zero?))
      ].compact

      positive_values = year_groups.select(&:positive?)

      if positive_values.length == 1
        items << format_year_group(positive_values.first)
      else
        items << "Years #{positive_values.first}"
        items += positive_values[1..].map(&:to_s)
      end

      items.to_sentence
    end
  end
end
