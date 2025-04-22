# frozen_string_literal: true

class String
  def normalise_whitespace
    result = self

    # \u200D is a zero-width joiner (ZWJ) which is used in the frontend to display the NHS number
    result = result.tr("\u200D", "")

    # \u00A0 is a non-breaking space
    result = result.tr("\u00A0", " ")

    result.strip.gsub(/\s+/, " ").presence
  end
end
