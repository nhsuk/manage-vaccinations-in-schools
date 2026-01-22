# frozen_string_literal: true

module MavisCLI
  module Clinics
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing clinic to a team"

      argument :team_workgroup,
               required: true,
               desc: "The workgroup of the team"
      argument :subteam_name, required: true, desc: "The name of the subteam"
      argument :ods_codes,
               type: :array,
               required: true,
               desc: "The ODS code of the clinic"

      def call(team_workgroup:, subteam_name:, ods_codes:, **)
        MavisCLI.load_rails

        team = Team.find_by(workgroup: team_workgroup)
        academic_year = AcademicYear.pending

        if team.nil?
          warn "Could not find team with workgroup #{team_workgroup}."
          return
        end

        subteam = team.subteams.find_by(name: subteam_name)

        if subteam.nil?
          warn "Could not find subteam with name #{subteam_name}."
          return
        end

        ActiveRecord::Base.transaction do
          ods_codes.each do |ods_code|
            location = Location.clinic.find_by(ods_code:)

            if location.nil?
              warn "Could not find clinic with ODS code #{ods_code}."
              next
            end

            if (
                 existing_team_locations =
                   location
                     .team_locations
                     .includes(:team, :subteam)
                     .where(academic_year:)
               )
              existing_team_locations.each do |existing_team_location|
                warn "#{ods_code} previously belonged to #{existing_team_location.name}."
              end
            end

            location.attach_to_team!(team, academic_year:, subteam:)
          end

          PatientTeamUpdater.call(team_scope: Team.where(id: team.id))
        end
      end
    end
  end

  register "clinics" do |prefix|
    prefix.register "add-to-team", Clinics::AddToTeam
  end
end
