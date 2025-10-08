# frozen_string_literal: true

module DaysBeforeToWeeksBefore
  extend ActiveSupport::Concern

  def weeks_before_consent_reminders
    return nil if days_before_consent_reminders.nil?
    (days_before_consent_reminders / 7).to_i
  end

  def weeks_before_consent_reminders=(value)
    self.days_before_consent_reminders = (value.blank? ? nil : value.to_i * 7)
  end

  def weeks_before_consent_requests
    return nil if days_before_consent_requests.nil?
    (days_before_consent_requests / 7).to_i
  end

  def weeks_before_consent_requests=(value)
    self.days_before_consent_requests = (value.blank? ? nil : value.to_i * 7)
  end

  def weeks_before_invitations
    return nil if days_before_invitations.nil?
    (days_before_invitations / 7).to_i
  end

  def weeks_before_invitations=(value)
    self.days_before_invitations = (value.blank? ? nil : value.to_i * 7)
  end
end
