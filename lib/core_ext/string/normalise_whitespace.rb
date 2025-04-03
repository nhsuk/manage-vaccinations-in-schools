# frozen_string_literal: true

class String
  # Normalises whitespace in a string by removing leading and trailing whitespace,
  # replacing multiple spaces with a single space, and returning nil if the result is empty.
  def normalise_whitespace
    strip.gsub(/\s+/, " ").presence
  end
end
