# frozen_string_literal: true

module MavisCLI
  module Schools
    class Show < Dry::CLI::Command
      desc "Show school information"

      argument :urn_or_ids,
               required: false,
               type: :array,
               desc: "School URN or ID (use --id to control)"

      option :id,
             type: :boolean,
             default: false,
             desc: "Provided school identifier is an ID"
      option :any_site,
             type: :boolean,
             default: false,
             desc: "Find any site when searching with URN"

      def call(urn_or_ids:, id: false, any_site: false, **)
        MavisCLI.load_rails

        if id && any_site
          raise "Cannot specify both --id and --any-site options"
        end

        locations =
          if id
            Location.where(id: urn_or_ids)
          elsif any_site
            Location.where(urn: urn_or_ids)
          else
            urn_or_ids.flat_map { Location.where_urn_and_site(it) }
          end

        academic_year = AcademicYear.current

        locations.each do |location|
          location
            .attributes
            .symbolize_keys
            .slice(
              :id,
              :name,
              :urn,
              :site,
              :status,
              :address_line_1,
              :address_line_2,
              :address_postcode,
              :address_town
            )
            .each { |name, value| puts "#{Rainbow(name).bright}: #{value}" }

          team_locations =
            location
              .team_locations
              .includes(:team, :subteam)
              .where(academic_year:)

          if team_locations.present?
            team_locations.each do |team_location|
              team = team_location.team
              puts "#{Rainbow("team id").bright}: #{team.id}"
              puts "#{Rainbow("team name").bright}: #{team.name}"

              if (subteam = team_location.subteam)
                puts "#{Rainbow("subteam id").bright}: #{subteam.id}"
                puts "#{Rainbow("subteam name").bright}: #{subteam.name}"
              end
            end
          else
            puts "#{Rainbow("team:").bright}: No team assigned"
          end

          puts Rainbow("programmes:").bright
          location.programmes.each do |programme|
            year_groups =
              location
                .location_programme_year_groups
                .where(programme:, academic_year:)
                .pluck_year_groups

            puts "  #{Rainbow(programme.type).bright}:"
            puts "    #{Rainbow("year groups").bright}: #{year_groups.join(", ")}"
          end

          puts "" if locations.count > 1
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "show", Schools::Show
  end
end
