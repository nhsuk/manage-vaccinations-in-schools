# frozen_string_literal: true

module MavisCLI
  module Schools
    class AddToOrganisation < Dry::CLI::Command
      desc "Add an existing school to an organisation"

      argument :ods_code,
               required: true,
               desc: "The ODS code of the organisation"
      argument :team, required: true, desc: "The team of the organisation"
      argument :urns,
               type: :array,
               required: true,
               desc: "The URN of the school"

      option :programmes,
             type: :array,
             desc: "The programmes administered at the school"

      def call(ods_code:, team:, urns:, programmes: [], **)
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code:)

        if organisation.nil?
          warn "Could not find organisation."
          return
        end

        team = organisation.teams.find_by(name: team)

        if team.nil?
          warn "Could not find team."
          return
        end

        programmes =
          if programmes.empty?
            organisation.programmes
          else
            Programme.where(type: programmes)
          end

        ActiveRecord::Base.transaction do
          urns.each do |urn|
            location = Location.school.find_by(urn:)

            if location.nil?
              warn "Could not find location: #{urn}"
              next
            end

            if !location.team_id.nil? && location.team_id != team.id
              warn "#{urn} previously belonged to #{location.team.name}"
            end

            location.update!(team:)
            location.create_default_programme_year_groups!(programmes)
          end
        end

        UnscheduledSessionsFactory.new.call
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "add-to-organisation", Schools::AddToOrganisation
  end
end
