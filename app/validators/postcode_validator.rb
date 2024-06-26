# frozen_string_literal: true

class PostcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    ukpc = UKPostcode.parse(value.to_s)
    unless ukpc.full_valid?
      record.errors.add(attribute, "Enter a valid postcode, such as SW1A 1AA")
    end
  end
end
