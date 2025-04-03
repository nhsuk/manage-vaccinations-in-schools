# frozen_string_literal: true

class String
  # Normalises whitespace in a string by removing leading and trailing whitespace,
  # replacing multiple spaces with a single space, and returning nil if the result is empty.
  def normalise_whitespace
    strip.gsub(/\s+/, " ").presence
  end

  def normalise_whitespace_regex(database_column_name)
    "regexp_replace(trim(#{database_column_name}), E'\\s+', ' ', 'g')"
  end
end
