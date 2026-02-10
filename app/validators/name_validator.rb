# frozen_string_literal: true

class NameValidator < ActiveModel::EachValidator
  PERSON_NAME_CHARS = [
    '\w', # ASCII alphanumeric characters
    '\u00C0-\u00D6', # Latin 1 Supplement letters (À-Ö)
    '\u00D8-\u00F6', # Latin 1 Supplement letters (Ø-ö)
    '\u00F8-\u017F', # Latin 1 Supplement & Latin Extended A letters (ø-ſ)
    '\u0020', # Space
    '\u0027', # Apostrophe (')
    '\u0060', # Grave accent (`), will be normalised to apostrophe
    '\u2019', # Preferred Unicode apostrophe ('), will be normalised
    '\u02BC', # Modifier apostrophe (ʼ), will be normalised
    '\u002E', # Full stop (.)
    '\u002D' # Hyphen (-)
  ].freeze

  SCHOOL_NAME_CHARS = [
    *PERSON_NAME_CHARS,
    '\u0026', # & Ampersand
    '\u002C', # , Comma
    '\u003B', # ; Semicolon
    '\u003A', # : Colon
    '\u0021', # ! Exclamation mark
    '\u003F', # ? Question mark
    '\u0022', # " Double quote
    '\u0028', # ( Left parenthesis
    '\u0029', # ) Right parenthesis
    '\u0040', # @ At sign
    '\u002F', # / Forward slash
    '\u005C', # \\ Backslash
    '\u002B', # + Plus sign
    '\u00B0' # ° Degree symbol
  ].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    chars = options[:school_name] ? SCHOOL_NAME_CHARS : PERSON_NAME_CHARS
    regex = /\A[#{chars.join}]+\z/

    unless value.match?(regex)
      record.errors.add(
        attribute,
        options[:message] || "includes invalid character(s)"
      )
    end
  end
end
