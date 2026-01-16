# frozen_string_literal: true

module MavisCLI
  module Schools
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing school to a team"

      argument :team_workgroup,
               required: true,
               desc: "The workgroup of the team"
      argument :subteam_name, required: true, desc: "The name of the subteam"
      argument :urns,
               type: :array,
               required: true,
               desc: "The URN of the school (including site, if applicable)"

      option :programmes,
             type: :array,
             desc: "The programmes administered at the school"

      def call(team_workgroup:, subteam_name:, urns:, programmes: [], **)
        MavisCLI.load_rails

        team = Team.find_by(workgroup: team_workgroup)

        if team.nil?
          warn "Could not find team with workgroup #{team_workgroup}."
          return
        end

        subteam = team.subteams.find_by(name: subteam_name)

        if subteam.nil?
          warn "Could not find subteam with name #{subteam_name}."
          return
        end

        programmes =
          (programmes.empty? ? team.programmes : Programme.find_all(programmes))

        academic_year = AcademicYear.pending

        ActiveRecord::Base.transaction do
          urns.each do |urn|
            location = Location.school.find_by_urn_and_site(urn)

            if location.nil?
              warn "Could not find school with URN #{urn}."
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
                warn "#{urn} previously belonged to #{existing_team_location.name}."
              end
            end

            location.attach_to_team!(team, academic_year:, subteam:)
            location.import_year_groups_from_gias!(academic_year:)
            location.import_default_programme_year_groups!(
              programmes,
              academic_year:
            )
          end
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "add-to-team", Schools::AddToTeam
  end
end
