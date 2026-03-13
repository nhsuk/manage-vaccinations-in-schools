# frozen_string_literal: true

module SmartQuoteSanitiser
  REPLACEMENTS = { "‘" => "'", "’" => "'", "“" => '"', "”" => '"' }.freeze

  def self.call(value)
    value&.gsub(/[#{REPLACEMENTS.keys.join}]/, REPLACEMENTS)
  end
end
