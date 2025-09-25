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

          if location.subteam.nil?
            puts "#{Rainbow("team:").bright}: No team assigned"
          else
            puts "#{Rainbow("team id").bright}: #{location.team.id}"
            puts "#{Rainbow("team name").bright}: #{location.team.name}"
            puts "#{Rainbow("subteam id").bright}: #{location.subteam.id}"
            puts "#{Rainbow("subteam name").bright}: #{location.subteam.name}"
          end

          puts Rainbow("programmes:").bright
          pyg = location.programme_year_groups(academic_year:)
          location.programmes.each do |programme|
            puts "  #{Rainbow(programme.type).bright}:"
            puts "    #{Rainbow("year groups").bright}: #{pyg[programme].join(", ")}"
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
