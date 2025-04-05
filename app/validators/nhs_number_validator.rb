# frozen_string_literal: true

class NHSNumberValidator < ActiveModel::EachValidator
  FORMAT = /\A(?:\d\s*){10}\z/

  def validate_each(record, attribute, value)
    if value.nil?
      record.errors.add(attribute, :blank) unless options[:allow_nil]
    elsif value.blank?
      record.errors.add(attribute, :blank) unless options[:allow_blank]
    elsif !FORMAT.match?(value)
      record.errors.add(attribute, :invalid)
    end
  end
end
