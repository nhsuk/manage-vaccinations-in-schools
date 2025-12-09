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
      word_items =
        if year_groups.any?(&:negative?) && year_groups.any?(&:zero?)
          %w[Nursery reception]
        elsif year_groups.any?(&:negative?)
          ["Nursery"]
        elsif year_groups.any?(&:zero?)
          ["Reception"]
        else
          []
        end

      positive_values = year_groups.select(&:positive?).sort

      numeric_items =
        if positive_values.length == 1
          [format_year_group(positive_values.first)]
        elsif positive_values.length > 1
          # Check if there is a continuous sequence of 3 or more values.
          if positive_values.length > 2 &&
               positive_values.each_cons(2).all? { |a, b| b == a + 1 }
            ["Years #{positive_values.first} to #{positive_values.last}"]
          else
            ["Years #{positive_values.first}"] +
              positive_values[1..].map(&:to_s)
          end
        else
          []
        end

      if word_items.present? && numeric_items.present?
        "#{word_items.join(", ")} and #{numeric_items.to_sentence.downcase_first}"
      elsif word_items.present?
        word_items.to_sentence
      else
        numeric_items.to_sentence
      end
    end
  end
end
