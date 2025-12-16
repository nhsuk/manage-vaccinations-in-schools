# frozen_string_literal: true

namespace :data_migration do
  desc "Remove clinic session notifications which are no longer used."
  task delete_clinic_session_notifications: :environment do
    SessionNotification.where(type: [1, 2]).delete_all
  end
end
