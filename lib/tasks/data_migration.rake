# frozen_string_literal: true

namespace :data_migration do
  desc "Creates clinic notifications from session notifications."
  task create_clinic_notifications: :environment do
    DataMigration::CreateClinicNotifications.call
  end
end
