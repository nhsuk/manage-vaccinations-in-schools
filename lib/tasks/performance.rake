# frozen_string_literal: true

namespace :performance do
  desc "Generate fake data to test performance of the service."
  task :generate, %i[count] => :environment do |_task, args|
    raise "Do not run in production." unless Rails.env.local?

    count = args[:count].to_i

    puts "Deleting existing data..."
    AccessLogEntry.delete_all
    Consent.delete_all
    Triage.delete_all
    SchoolMove.delete_all
    ParentRelationship.delete_all
    Parent.delete_all
    PatientSession.delete_all
    VaccinationRecord.delete_all
    Patient.delete_all

    academic_year = AcademicYear.current

    Organisation.find_each do |organisation|
      puts "For organisation: #{organisation.name}"

      sessions_by_school_id =
        organisation
          .sessions
          .where(academic_year:)
          .joins(:location)
          .merge(Location.school)
          .index_by(&:location_id)

      puts "Building patients..."
      patients =
        count.times.map do
          FactoryBot.build(
            :patient,
            organisation:,
            school_id: sessions_by_school_id.keys.sample,
            year_group: organisation.year_groups.sample,
            home_educated: nil
          )
        end

      puts "Importing patients..."
      Patient.import!(patients)

      puts "Building patient sessions..."
      generic_clinic_session =
        organisation.generic_clinic_session(academic_year:)

      patient_sessions =
        patients.flat_map do |patient|
          [
            PatientSession.new(patient:, session: generic_clinic_session),
            PatientSession.new(
              patient:,
              session: sessions_by_school_id.fetch(patient.school_id)
            )
          ]
        end

      puts "Importing patient sessions..."
      PatientSession.import!(patient_sessions)

      puts "Building vaccination records..."
      vaccination_records =
        organisation.programmes.flat_map do |programme|
          patients
            .sample(count / 10)
            .map do |patient|
              FactoryBot.build(
                :vaccination_record,
                patient:,
                organisation:,
                programme:
              )
            end
        end

      puts "Importing vaccination records..."
      VaccinationRecord.import!(vaccination_records)
    end
  end
end
