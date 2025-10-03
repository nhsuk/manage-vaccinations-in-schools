# frozen_string_literal: true

module Consentable
  extend ActiveSupport::Concern

  def open_consent_at = send_consent_requests_at

  def close_consent_at
    return nil if dates.empty?
    dates.max - 1.day
  end

  def open_for_consent?
    close_consent_at&.today? || close_consent_at&.future? || false
  end

  def next_reminder_dates
    return [] if days_before_consent_reminders.nil?

    reminder_dates = dates.map { it - days_before_consent_reminders.days }
    reminder_dates.select(&:future?)
  end

  def next_reminder_date = next_reminder_dates.first
end
