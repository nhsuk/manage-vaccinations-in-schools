# frozen_string_literal: true

namespace :vaccination_records do
  desc "Recalculate and update notify_parents for all vaccination records"
  task update_notify_parents: :environment do
    VaccinationRecord.find_each do |vaccination_record|
      value = VaccinationNotificationCriteria.call(vaccination_record:)

      vaccination_record.update_column(:notify_parents, value)
    end
  end
end
