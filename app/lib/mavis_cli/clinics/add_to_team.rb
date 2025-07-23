# frozen_string_literal: true

module MavisCLI
  module Clinics
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing clinic to a team"

      argument :team_ods_code, required: true, desc: "The ODS code of the team"
      argument :subteam, required: true, desc: "The subteam of the team"
      argument :clinic_ods_codes,
               type: :array,
               required: true,
               desc: "The ODS codes of the clinics"

      def call(team_ods_code:, subteam:, clinic_ods_codes:, **)
        MavisCLI.load_rails

        # TODO: Select the right team based on an identifier.
        team =
          Team.joins(:organisation).find_by(
            organisation: {
              ods_code: team_ods_code
            }
          )

        if team.nil?
          warn "Could not find team."
          return
        end

        subteam = team.subteams.find_by(name: subteam)

        if subteam.nil?
          warn "Could not find subteam."
          return
        end

        ActiveRecord::Base.transaction do
          clinic_ods_codes.each do |ods_code|
            location = Location.clinic.find_by(ods_code:)

            if location.nil?
              warn "Could not find location: #{ods_code}"
              next
            end

            if !location.subteam_id.nil? && location.subteam_id != subteam.id
              warn "#{ods_code} previously belonged to #{location.subteam.name}"
            end

            location.update!(subteam:)
          end
        end
      end
    end
  end

  register "clinics" do |prefix|
    prefix.register "add-to-team", Clinics::AddToTeam
  end
end
