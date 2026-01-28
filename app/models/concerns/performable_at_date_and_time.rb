# frozen_string_literal: true

module PerformableAtDateAndTime
  extend ActiveSupport::Concern

  def performed_at
    if performed_at_time
      performed_at_time.change(
        year: performed_at_date.year,
        month: performed_at_date.month,
        day: performed_at_date.day
      )
    else
      performed_at_date
    end
  end

  def performed_at=(value)
    if value.is_a?(Date)
      self.performed_at_date = value
      self.performed_at_time = nil
    else
      self.performed_at_date = value&.to_date
      self.performed_at_time = value&.to_time
    end
  end
end
