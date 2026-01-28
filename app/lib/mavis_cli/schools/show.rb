# frozen_string_literal: true

module MavisCLI
  module Schools
    class Show < Dry::CLI::Command
      include ::MavisCLIHelpers

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
      option :show_patients,
             aliases: %w[-p],
             type: :boolean,
             default: false,
             desc: "Show patient info"

      def call(
        urn_or_ids:,
        id: false,
        any_site: false,
        show_patients: false,
        **
      )
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
          puts(Rainbow("-" * 64).bright) if locations.count > 1

          location
            .attributes
            .symbolize_keys
            .slice(
              :id,
              :name,
              :urn,
              :site,
              :status,
              :gias_phase,
              :gias_year_groups,
              :gias_establishment_number,
              :gias_local_authority_code,
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
            puts "#{Rainbow("team").bright}: No team assigned"
          end

          puts ""
          print_attributes total_patients: location.patient_locations.count
          if show_patients
            patient_locations =
              location
                .patient_locations
                .preload(
                  :attendance_records,
                  :gillick_assessments,
                  :pre_screenings,
                  :vaccination_records
                )
                .current

            attendance_records =
              location.attendance_records.for_academic_year(academic_year)
            gillick_assessments =
              location.gillick_assessments.for_academic_year(academic_year)

            print_attributes(
              _indent: 1,
              in_current_academic_year: {
                _value: patient_locations.count,
                with_attendance_records: attendance_records.count,
                with_gillick_assessments: gillick_assessments.count
              }
            )
          end

          puts "", Rainbow("programmes:").bright
          location.programmes.each do |programme|
            year_groups =
              location
                .location_programme_year_groups
                .where(
                  programme_type: programme.type,
                  location_year_group: {
                    academic_year:
                  }
                )
                .pluck_year_groups

            puts "  #{Rainbow(programme.type).bright}:"
            puts "    #{Rainbow("year groups").bright}: #{year_groups.join(", ")}"
          end

          puts ""

          if Location.where(urn: location.urn).count > 1
            puts "#{Rainbow("other locations with the same URN").bright}:"
            Location
              .where(urn: location.urn)
              .find_each do |other_location|
                next if other_location == location

                puts "  #{Rainbow(other_location.urn_and_site).bright}: #{other_location.name}"
              end
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
