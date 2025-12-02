# frozen_string_literal: true

module MavisCLI
  module Schools
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing school to a team"

      argument :workgroup, required: true, desc: "The ODS code of the team"
      argument :subteam, required: true, desc: "The subteam of the team"
      argument :urns,
               type: :array,
               required: true,
               desc: "The URN of the school"

      option :programmes,
             type: :array,
             desc: "The programmes administered at the school"

      def call(workgroup:, subteam:, urns:, programmes: [], **)
        MavisCLI.load_rails

        team = Team.find_by(workgroup:)

        if team.nil?
          warn "Could not find team."
          return
        end

        subteam = team.subteams.find_by(name: subteam)

        programmes =
          (programmes.empty? ? team.programmes : Programme.find_all(programmes))

        academic_year = AcademicYear.pending

        ActiveRecord::Base.transaction do
          urns.each do |urn|
            location = Location.school.find_by_urn_and_site(urn)

            if location.nil?
              warn "Could not find location: #{urn}"
              next
            end

            if (
                 existing_team_locations =
                   location.team_locations.includes(:team).where(academic_year:)
               )
              existing_team_locations.each do |existing_team_location|
                warn "#{ods_code} previously belonged to #{existing_team_location.name}"
              end
            end

            team_location =
              location.attach_to_team!(team, academic_year:, subteam:)

            location.import_year_groups_from_gias!(academic_year:)
            location.import_default_programme_year_groups!(
              programmes,
              academic_year:
            )

            TeamLocationSessionsFactory.call(team_location)
          end
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "add-to-team", Schools::AddToTeam
  end
end
