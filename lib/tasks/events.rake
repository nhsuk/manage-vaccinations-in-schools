# frozen_string_literal: true

namespace :events do
  desc "Clear all reportable events"
  task clear: :environment do
    ReportableEvent.delete_all
  end

  desc "Write all VaccinationRecord events"
  task write_vaccination_records: :environment do
    puts "#{VaccinationRecord.count} vaccination records"
    puts "#{ReportableEvent.count} reportable events"

    VaccinationRecord.all.find_each do |vaccination|
      re =
        ReportableEvent.find_or_initialize_by(
          event_timestamp: vaccination.performed_at,
          event_type: ["vaccination", vaccination.outcome].join("_"),
          source_id: vaccination.id,
          source_type: vaccination.class.name
        )

      re.copy_attributes_from_references(
        patient: vaccination.patient,
        school: vaccination.location,
        vaccination_record: vaccination,
        vaccine: vaccination.vaccine,
        team: vaccination.team,
        organisation: vaccination.team&.organisation,
        programme: vaccination.programme
      )

      re.save!
    end
  end
end
