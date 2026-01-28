# frozen_string_literal: true

class TimeParamsValidator
  attr_reader :field_name, :object, :params

  def initialize(field_name:, object:, params:)
    @field_name = field_name
    @object = object
    @params = params
  end

  def time_params_as_struct
    time_params = [
      params["#{field_name}(4i)"],
      params["#{field_name}(5i)"],
      params["#{field_name}(6i)"]
    ]
    Struct.new(:hour, :minute, :second).new(*time_params)
  end

  def time_params_valid?
    time = time_params_as_struct

    return true if [time.hour, time.minute, time.second].all?(&:blank?)

    if time.second.blank?
      object.errors.add(field_name, :missing_second)
    elsif time.minute.blank?
      object.errors.add(field_name, :missing_minute)
    elsif time.hour.blank?
      object.errors.add(field_name, :missing_hour)
    else
      begin
        Time.zone.local(
          2000,
          1,
          1,
          time.hour.to_i,
          time.minute.to_i,
          time.second.to_i
        )
      rescue ArgumentError
        object.errors.add(field_name, :blank)
      end
    end

    object.errors.none?
  end
end
