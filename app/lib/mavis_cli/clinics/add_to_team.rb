# frozen_string_literal: true

module MavisCLI
  module Clinics
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing clinic to a team"

      argument :workgroup, required: true, desc: "The ODS code of the team"
      argument :subteam, required: true, desc: "The subteam of the team"
      argument :ods_codes,
               type: :array,
               required: true,
               desc: "The ODS codes of the clinics"

      def call(workgroup:, subteam:, ods_codes:, **)
        MavisCLI.load_rails

        team = Team.find_by(workgroup:)
        academic_year = AcademicYear.current

        if team.nil?
          warn "Could not find team."
          return
        end

        subteam = team.subteams.find_by(name: subteam)

        ActiveRecord::Base.transaction do
          ods_codes.each do |ods_code|
            location = Location.clinic.find_by(ods_code:)

            if location.nil?
              warn "Could not find location: #{ods_code}"
              next
            end

            if !location.subteam_id.nil? && location.subteam_id != subteam.id
              warn "#{ods_code} previously belonged to #{location.subteam.name}"
            end

            location.attach_to_team!(team, academic_year:, subteam:)
          end
        end
      end
    end
  end

  register "clinics" do |prefix|
    prefix.register "add-to-team", Clinics::AddToTeam
  end
end
