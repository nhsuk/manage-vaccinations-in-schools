# frozen_string_literal: true

module MavisCLI
  class AccessLog < Dry::CLI::Command
    desc "View the access log"

    option :patient_id, aliases: %w[-p], desc: "ID of the patient"
    option :user_email, aliases: %w[-u], desc: "Email address of the user"

    def call(patient_id: nil, user_email: nil, **)
      MavisCLI.load_rails

      scope = AccessLogEntry

      if patient_id.present?
        patient = Patient.find(patient_id)
        scope = scope.where(patient:)
      end

      if user_email.present?
        user = User.find_by!(email: user_email)
        scope = scope.where(user:)
      end

      print_log_entries(
        scope,
        show_patient: patient_id.blank?,
        show_user: user_email.blank?
      )
    end

    def print_log_entries(scope, show_patient: false, show_user: false)
      scope
        .includes(:patient, :user)
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
  end

  register "access-log", AccessLog
end
