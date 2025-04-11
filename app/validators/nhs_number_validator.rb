# frozen_string_literal: true

class NHSNumberValidator < ActiveModel::EachValidator
  FORMAT = /\A(?:\d\s*){10}\z/

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, :blank) unless options[:allow_blank]
    elsif value.nil?
      record.errors.add(attribute, :blank) unless options[:allow_nil]
    elsif !FORMAT.match?(value)
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end
end
