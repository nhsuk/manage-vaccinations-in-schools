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
        AcademicYear.current

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

            if !location.subteam_id.nil? && location.subteam_id != subteam.id
              warn "#{urn} previously belonged to #{location.subteam.name}"
            end

            location.attach_to_team!(team, academic_year:, subteam:)
            location.import_year_groups_from_gias!(academic_year:)
            location.import_default_programme_year_groups!(
              programmes,
              academic_year:
            )

            LocationSessionsFactory.call(location, academic_year:)
          end
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "add-to-team", Schools::AddToTeam
  end
end
