# frozen_string_literal: true

class DateParamsValidator
  attr_reader :field_name, :object, :params

  def initialize(field_name:, object:, params:)
    @field_name = field_name
    @object = object
    @params = params
  end

  def date_params_as_struct
    date_params = [
      params["#{field_name}(1i)"],
      params["#{field_name}(2i)"],
      params["#{field_name}(3i)"]
    ]
    Struct.new(:year, :month, :day).new(*date_params)
  end

  def date_params_valid?
    date = date_params_as_struct

    # Let the model decide if this is valid
    return true if [date.year, date.month, date.day].all?(&:blank?)

    if date.day.blank?
      object.errors.add(field_name, :missing_day)
    elsif date.month.blank?
      object.errors.add(field_name, :missing_month)
    elsif date.year.blank?
      object.errors.add(field_name, :missing_year)
    elsif date.year.to_i < 1000
      object.errors.add(field_name, :missing_year)
    else
      begin
        Date.new(date.year.to_i, date.month.to_i, date.day.to_i)
      rescue Date::Error
        object.errors.add(field_name, :blank)
      end
    end

    object.errors.none?
  end
end
