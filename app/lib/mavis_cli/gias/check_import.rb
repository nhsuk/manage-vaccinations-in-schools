#frozen_string_literal: true

module MavisCLI
  module GIAS
    class CheckImport < Dry::CLI::Command
      desc "Check what changes will be introduced with a GIAS import"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/dfe-schools.zip",
             desc: "GIAS database file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        row_count = ::GIAS.row_count(input_file)
        progress_bar = MavisCLI.progress_bar(row_count)

        results = ::GIAS.check_import(input_file:, progress_bar:)

        new_schools = results[:new_schools]
        schools_with_future_sessions = results[:schools_with_future_sessions]
        schools_without_future_sessions =
          results[:schools_without_future_sessions]

        closed_schools_count =
          schools_without_future_sessions[:closed].count +
            schools_with_future_sessions[:closed].count
        closing_schools_count =
          schools_without_future_sessions[:closing].count +
            schools_with_future_sessions[:closing].count

        closed_schools_with_future_sessions_pct =
          calculate_percentage(schools_with_future_sessions, :closed)
        closing_schools_with_future_sessions_pct =
          calculate_percentage(schools_with_future_sessions, :closing)
        schools_with_changed_year_groups_pct =
          calculate_percentage(
            schools_with_future_sessions,
            :year_group_changes
          )

        puts <<~OUTPUT
                  New schools (total): #{new_schools.count}
               Closed schools (total): #{closed_schools_count}
Proposed to be closed schools (total): #{closing_schools_count}

   Existing schools with future sessions: #{schools_with_future_sessions[:existing].count}
               That are closed in import: #{schools_with_future_sessions[:closed].count} (#{closed_schools_with_future_sessions_pct * 100}%)
That are proposed to be closed in import: #{schools_with_future_sessions[:closing].count} (#{closing_schools_with_future_sessions_pct * 100}%)
            That have year group changes: #{schools_with_future_sessions[:year_group_changes].count} (#{schools_with_changed_year_groups_pct * 100}%)
        OUTPUT

        if schools_with_future_sessions[:closed].any?
          puts "\nURNs of closed schools with future sessions:"
          schools_with_future_sessions[:closed].sort.each do |urn, successors|
            if successors.any?
              successor_info = format_successors_with_teams(successors)
              puts "  #{urn} -> successor(s): #{successor_info}"
            else
              puts "  #{urn}"
            end
          end
        end

        if schools_with_future_sessions[:closing].any?
          puts "\nURNs of schools that will be closing, with future sessions:"
          schools_with_future_sessions[:closing].sort.each do |urn, successors|
            if successors.any?
              successor_info = format_successors_with_teams(successors)
              puts "  #{urn} -> successor(s): #{successor_info}"
            else
              puts "  #{urn}"
            end
          end
        end

        if schools_with_future_sessions[:year_group_changes].any?
          puts "\nURNs of schools with year group changes, with future sessions:"
          schools_with_future_sessions[
            :year_group_changes
          ].each do |urn, change|
            puts "  #{urn}:"
            puts "    Current:  #{change[:current]}"
            puts "    New:      #{change[:new]}"
          end
        end
      end

      private

      def format_successors_with_teams(successor_urns)
        annotated_successor_urns =
          successor_urns.map do |successor_urn|
            locations = Location.school.where(urn: successor_urn)

            if locations.count == 1
              teams = locations.sole.teams.uniq
              if teams.any?
                team_names = teams.map(&:name).join(", ")
                "#{successor_urn} (Team: #{team_names})"
              else
                "#{successor_urn} (no team)"
              end
            elsif locations.count > 1
              site_urns =
                locations.where.not(site: nil).map(&:urn_and_site).join(", ")
              team_names =
                locations
                  .where.not(site: nil)
                  .flat_map(&:teams)
                  .uniq
                  .map(&:name)
                  .join(", ")
              "#{site_urns} (Teams: #{team_names})"
            else
              "#{successor_urn} (not found)"
            end
          end

        annotated_successor_urns.join(", ")
      end

      def calculate_percentage(schools_set, metric)
        if schools_set[:existing].count.positive?
          schools_set[metric].count.to_f / schools_set[:existing].count
        else
          0.0
        end
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "check-import", GIAS::CheckImport
  end
end
