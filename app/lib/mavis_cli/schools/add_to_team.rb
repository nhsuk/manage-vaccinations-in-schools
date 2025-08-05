# frozen_string_literal: true

module MavisCLI
  module Schools
    class AddToTeam < Dry::CLI::Command
      desc "Add an existing school to a team"

      argument :ods_code, required: true, desc: "The ODS code of the team"
      argument :subteam, required: true, desc: "The subteam of the team"
      argument :urns,
               type: :array,
               required: true,
               desc: "The URN of the school"

      option :programmes,
             type: :array,
             desc: "The programmes administered at the school"

      def call(ods_code:, subteam:, urns:, programmes: [], **)
        MavisCLI.load_rails

        team = Team.find_by(ods_code:)

        if team.nil?
          warn "Could not find team."
          return
        end

        subteam = team.subteams.find_by(name: subteam)

        if subteam.nil?
          warn "Could not find subteam."
          return
        end

        programmes =
          if programmes.empty?
            team.programmes
          else
            Programme.where(type: programmes)
          end

        academic_year = AcademicYear.pending

        ActiveRecord::Base.transaction do
          urns.each do |urn|
            location = Location.school.find_by(urn:)

            if location.nil?
              warn "Could not find location: #{urn}"
              next
            end

            if !location.subteam_id.nil? && location.subteam_id != subteam.id
              warn "#{urn} previously belonged to #{location.subteam.name}"
            end

            location.update!(subteam:)
            location.create_default_programme_year_groups!(programmes)

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
