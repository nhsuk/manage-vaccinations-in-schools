# frozen_string_literal: true

namespace :events do
  desc "Clear all reportable events"
  task clear: :environment do
    ReportableVaccinationEvent.delete_all
  end

  desc "Write all VaccinationRecord events"
  task write_vaccination_records: :environment do
    puts "#{VaccinationRecord.count} vaccination records"
    puts "#{ReportableEvent.count} reportable events"

    VaccinationRecord.all.find_each do |vaccination|
      vaccination.create_or_update_reportable_vaccination_event!
    end
  end
end
