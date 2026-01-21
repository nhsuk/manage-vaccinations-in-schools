# frozen_string_literal: true

class BatchNameValidator < ActiveModel::EachValidator
  FORMAT = /\A[A-Za-z0-9]+\z/
  MIN_LENGTH = 2
  MAX_LENGTH = 100

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, :blank)
    elsif value.length < MIN_LENGTH
      record.errors.add(attribute, :too_short, count: MIN_LENGTH)
    elsif value.length > MAX_LENGTH
      record.errors.add(attribute, :too_long, count: MAX_LENGTH)
    elsif value !~ FORMAT
      record.errors.add(attribute, :invalid)
    end
  end
end
