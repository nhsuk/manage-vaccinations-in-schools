# frozen_string_literal: true

class TimeParamsNormalizer
  def initialize(params:, field_name:)
    @params = params
    @field_name = field_name
  end

  HOUR_SUFFIX = "(4i)"
  MINUTE_SUFFIX = "(5i)"
  SECOND_SUFFIX = "(6i)"

  def call!
    if hour_blank? && minute_blank? && seconds_present?
      @params["#{@field_name}#{SECOND_SUFFIX}"] = ""
    end
    @params
  end

  def self.call!(...) = new(...).call!

  private_class_method :new

  private

  def hour_blank?
    @params["#{@field_name}#{HOUR_SUFFIX}"].blank?
  end

  def minute_blank?
    @params["#{@field_name}#{MINUTE_SUFFIX}"].blank?
  end

  def seconds_present?
    @params.key?("#{@field_name}#{SECOND_SUFFIX}")
  end
end
