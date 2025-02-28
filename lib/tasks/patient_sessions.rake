# frozen_string_literal: true

namespace :patient_sessions do
  desc "Ensures all patients exist in both schools and clinics."
  task add_to_clinic: :environment do |_task, _args|
    count = PatientSession.count
    puts "#{count} existing patient sessions."

    to_import =
      PatientSession
        .includes(session: :organisation)
        .map do
          PatientSession.new(
            patient_id: it.patient_id,
            session: it.session.organisation.generic_clinic_session
          )
        end

    PatientSession.import(to_import, on_duplicate_key_ignore: :all)

    puts "#{PatientSession.count - count} new patient sessions created."
  end
end
