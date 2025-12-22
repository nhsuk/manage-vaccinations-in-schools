# frozen_string_literal: true

require "rainbow/refinement"

module MavisCLIHelpers
  using Rainbow

  # rubocop:disable Lint/UnderscorePrefixedVariableName
  # rubocop:disable Rails/Output
  def print_attributes(_indent: 0, **attributes)
    attributes.each do |key, value|
      label = key.to_s.humanize(capitalize: false)
      puts "#{" " * _indent * 2}#{Rainbow(label).bright}: #{value}"
    end
  end
  # rubocop:enable Rails/Output
  # rubocop:enable Lint/UnderscorePrefixedVariableName
end
