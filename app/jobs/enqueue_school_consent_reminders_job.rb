# frozen_string_literal: true

class EnqueueSchoolConsentRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session.send_consent_reminders.joins(:location).merge(Location.school)

    sessions.find_each do |session|
      SendAutomaticSchoolConsentRemindersJob.perform_later(session)
    end
  end
end
