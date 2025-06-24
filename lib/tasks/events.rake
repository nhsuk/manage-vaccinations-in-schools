# frozen_string_literal: true

namespace :events do
  namespace :vaccinations do
    desc "Clear all reportable vaccination events"
    task clear: :environment do
      ReportableVaccinationEvent.delete_all
    end

    desc "Write reportable vaccination events for all VaccinationRecords"
    task write_all: :environment do
      puts "#{VaccinationRecord.count} vaccination records"

      VaccinationRecord.all.find_each do |vaccination|
        vaccination.create_or_update_reportable_vaccination_event
      end

      puts "#{ReportableVaccinationEvent.count} reportable events"
    end
  end

  namespace :consents do
    desc "Clear all reportable consent events"
    task clear: :environment do
      ReportableConsentEvent.delete_all
    end

    desc "Write reportable consent events for all Consent records"
    task write_all: :environment do
      puts "#{Consent.count} consent records"
      
      Consent.all.find_each do |consent|
        consent.create_or_update_reportable_consent_event
      end
      puts "#{ReportableConsentEvent.count} reportable events"
    end
  end
  
end
