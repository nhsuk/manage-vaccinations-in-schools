# frozen_string_literal: true

require "rainbow/refinement"

module MavisCLIHelpers
  using Rainbow

  # rubocop:disable Lint/UnderscorePrefixedVariableName
  # rubocop:disable Rails/Output
  def print_attributes(_indent: 0, **attributes)
    attributes.each do |key, value|
      if value.is_a?(Hash)
        nested_attributes = value
        value = nested_attributes.delete(:_value)
      end
      label = key.to_s.humanize(capitalize: false)
      puts "#{" " * _indent * 2}#{Rainbow(label).bright}: #{value}"

      if nested_attributes
        print_attributes(_indent: _indent + 1, **nested_attributes)
      end
    end
  end
  # rubocop:enable Rails/Output
  # rubocop:enable Lint/UnderscorePrefixedVariableName
end
