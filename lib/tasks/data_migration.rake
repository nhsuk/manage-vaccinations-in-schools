# frozen_string_literal: true

namespace :data_migration do
  desc "Remove clinic session notifications which are no longer used."
  task delete_clinic_session_notifications: :environment do
    SessionNotification.where(type: [1, 2]).delete_all
  end

  desc "Delete sessions that have not been scheduled."
  task delete_unscheduled_sessions: :environment do
    destroyed_sessions =
      Session
        .where(dates: [])
        .find_each
        .filter_map do |session|
          next if session.consent_notifications.exists?
          next if session.session_notifications.exists?
          next if session.vaccination_records.exists?
          next if ConsentForm.where(original_session: session).exists?

          session.tap(&:destroy!)
        end

    puts "Deleted #{destroyed_sessions.count} sessions"
  end
end
