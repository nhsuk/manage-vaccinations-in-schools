# frozen_string_literal: true

module YearGroupsHelper
  def format_year_group(year_group)
    if year_group == -4
      "Early (1st year)"
    elsif year_group == -3
      "Early (2nd year)"
    elsif year_group == -2
      "Nursery (1st year)"
    elsif year_group == -1
      "Nursery (2nd year)"
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
      positive_values, negative_values = year_groups.sort.partition(&:positive?)

      word_items =
        negative_values.each_with_index.map do |value, index|
          string = format_year_group(value)
          index.zero? ? string : string.downcase_first
        end

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
