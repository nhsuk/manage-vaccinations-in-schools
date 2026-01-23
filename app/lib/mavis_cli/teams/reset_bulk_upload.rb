# frozen_string_literal: true

module MavisCLI
  module Teams
    class ResetBulkUpload < Dry::CLI::Command
      desc "Reset bulk upload teams by removing all immunisation imports and associated data"

      option :workgroup,
             desc: "The workgroup of a specific team to reset (optional)"
      option :force,
             desc:
               "Ignore check if sync_national_reporting_to_imms_api feature is enabled"

      def call(workgroup: nil, force: false, **)
        MavisCLI.load_rails

        if !force && Flipper.enabled?(:sync_national_reporting_to_imms_api)
          puts "Error: This operation is not allowed while sync_national_reporting_to_imms_api is enabled."
          return
        end

        teams = find_teams(workgroup)

        if teams.empty?
          puts "No bulk upload teams found."
          return
        end

        puts "Found #{teams.count} bulk upload team(s) to reset:"
        teams.each do |team|
          puts "  - #{team.name} (#{team.workgroup})"
          puts "    - Immunisation imports: #{ImmunisationImport.where(team:).count}"
          puts "    - Total patients: #{find_patients_for_team(team).count}"
          puts "    - Vaccination records: #{find_vaccination_records_for_team(team).count}"
        end
        puts

        unless MavisCLI.prompt_to_continue(
                 "This will permanently delete all data associated with the above teams. Continue? (y/n) "
               )
          puts "Operation cancelled."
          return
        end

        teams.each do |team|
          puts "Resetting #{team.name} (#{team.workgroup})..."
          reset_team(team)
        end

        puts "\nAll teams reset successfully."
      end

      private

      def find_teams(workgroup)
        if workgroup.present?
          team = Team.find_by(workgroup:)
          raise ArgumentError, "Team not found: #{workgroup}" if team.nil?

          unless team.has_upload_only_access?
            raise ArgumentError, "Team #{workgroup} is not a bulk upload team"
          end

          [team]
        else
          Team.where(type: :upload_only)
        end
      end

      def reset_team(team)
        ActiveRecord::Base.transaction do
          immunisation_imports = ImmunisationImport.where(team:)
          puts "  - Found #{immunisation_imports.count} immunisation import(s)"

          patient_ids = find_patients_for_team(team).ids
          puts "  - Found #{patient_ids.count} patient(s) in this team"

          vaccination_records = find_vaccination_records_for_team(team)
          puts "  - Found #{vaccination_records.count} vaccination record(s) in this team's imports"

          puts "Destroying vaccination records..."
          vaccination_records.destroy_all

          puts "Destroying immunisation imports..."
          immunisation_imports.destroy_all

          puts "Updating patient-team relationships..."
          PatientTeamUpdater.call(patient_scope: Patient.where(id: patient_ids))

          patients_to_destroy =
            Patient
              .where(id: patient_ids)
              .left_outer_joins(:patient_teams)
              .group("patients.id")
              .having("COUNT(patient_teams.team_id) = 0")
          puts "  - Found #{patients_to_destroy.count} patient(s) who were in the imports, and no longer have teams"

          puts "Destroying patients..."
          patients_to_destroy.destroy_all
        end
      end

      def find_patients_for_team(team)
        Patient.joins(:patient_teams).where(patient_teams: { team: }).distinct
      end

      def find_vaccination_records_for_team(team)
        VaccinationRecord.joins(:immunisation_imports).where(
          immunisation_imports: {
            team:
          }
        )
      end
    end
  end

  register "teams" do |prefix|
    prefix.register "reset-bulk-upload", Teams::ResetBulkUpload
  end
end
