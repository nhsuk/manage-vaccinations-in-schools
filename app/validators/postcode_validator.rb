# frozen_string_literal: true

class PostcodeValidator < ActiveModel::EachValidator
  ADDRESS_PSEUDO_POSTCODES = [
    "ZZ99 3VZ", # No fixed abode
    "ZZ99 3WZ", # Address not known
    "ZZ99 3CZ" # (England/UK) address not otherwise specified
  ].freeze

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, :blank) unless options[:allow_blank]
    elsif value.nil?
      record.errors.add(attribute, :blank) unless options[:allow_nil]
    else
      postcode = UKPostcode.parse(value.to_s)

      unless PostcodeValidator.postcode_valid?(postcode)
        record.errors.add(attribute, "Enter a valid postcode, such as SW1A 1AA")
      end
    end
  end

  def self.postcode_valid?(postcode)
    postcode.full_valid? || postcode.to_s.in?(ADDRESS_PSEUDO_POSTCODES)
  end
end
