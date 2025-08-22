# frozen_string_literal: true

module ApostropheNormaliser
  def self.call(value)
    pattern = <<-PATTERN
      (
        \u0060   # Grave accent, we have one instance of this already so far
        | \u2019 # Right single quotation mark, the preferred Unicode apostrophe
                 # but not supported by PDS
        | \u02BC # Modifier letter apostrophe, also not supported by PDS
      )
    PATTERN

    value&.gsub(Regexp.new(pattern, Regexp::EXTENDED), "'")
  end
end
