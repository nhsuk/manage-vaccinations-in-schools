# frozen_string_literal: true

namespace :access_log do
  desc "Print access log entries for a user."
  task :for_user, [:email] => :environment do |_task, args|
    user = User.find_by!(email: args[:email])
    entries = AccessLogEntry.where(user:)
    print_log_entries(entries, show_patient: true)
  end

  desc "Print access log entries for a patient."
  task :for_patient, [:id] => :environment do |_task, args|
    patient = Patient.find(args[:id])
    entries = AccessLogEntry.where(patient:)
    print_log_entries(entries, show_user: true)
  end
end

def print_log_entries(entries, show_patient: false, show_user: false)
  entries
    .eager_load(:patient, :user)
    .find_each do |entry|
      parts = [
        entry.created_at.iso8601,
        "#{entry.controller}/#{entry.action}",
        show_patient ? entry.patient.full_name : nil,
        show_user ? entry.user.full_name : nil
      ].compact

      puts parts.join(" - ")
    end
end
