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

        require "zip"

        schools_with_future_sessions = {
          existing:
            Set.new(
              Location
                .school
                .joins(sessions: :session_dates)
                .where("session_dates.value >= ?", Time.zone.today)
                .pluck(:urn)
            ),
          closed: Set.new,
          closing: Set.new
        }
        schools_without_future_sessions = { closed: Set.new, closing: Set.new }

        existing_schools = Set.new(Location.school.pluck(:urn))
        team_schools = Set.new(Location.school.joins(:subteam).pluck(:urn))

        new_schools = Set.new

        Zip::File.open(input_file) do |zip|
          csv_entry = zip.glob("edubasealldata*.csv").first
          csv_content = csv_entry.get_input_stream.read

          CSV.parse(
            csv_content,
            headers: true,
            encoding: "ISO-8859-1:UTF-8"
          ) do |row|
            gias_establishment_number = row["EstablishmentNumber"]
            next if gias_establishment_number.blank? # closed school that never opened

            urn = row["URN"]
            new_status = row["EstablishmentStatus (name)"]

            if urn.in?(schools_with_future_sessions[:existing])
              check_for_school_closure(row, schools_with_future_sessions)

              # check_for_year_group_changes(urn, closed_schools)
            elsif urn.in?(team_schools)
              check_for_school_closure(row, schools_without_future_sessions)
            elsif !urn.in?(existing_schools) &&
                  new_status.in?(["Open", "Open, but proposed to close"])
              new_schools << urn
            end
          end
        end

        closed_schools_count =
          schools_without_future_sessions[:closed].count +
            schools_with_future_sessions[:closed].count
        closing_schools_count =
          schools_without_future_sessions[:closing].count +
            schools_with_future_sessions[:closing].count

        closed_schools_with_future_sessions_pct =
          schools_with_future_sessions[:closed].count.to_f /
            schools_with_future_sessions[:existing].count

        closing_schools_with_future_sessions_pct =
          schools_with_future_sessions[:closing].count.to_f /
            schools_with_future_sessions[:existing].count

        puts <<~OUTPUT
                  New schools (total): #{new_schools.count}
               Closed schools (total): #{closed_schools_count}
Proposed to be closed schools (total): #{closing_schools_count}

   Existing schools with future sessions: #{schools_with_future_sessions[:existing].count}
               That are closed in import: #{schools_with_future_sessions[:closed].count} (#{closed_schools_with_future_sessions_pct * 100}%)
That are proposed to be closed in import: #{schools_with_future_sessions[:closing].count} (#{closing_schools_with_future_sessions_pct * 100}%)
        OUTPUT

        puts <<~OUTPUT if schools_with_future_sessions[:closed].any?

URNs of closed schools with future sessions:
  #{schools_with_future_sessions[:closed].to_a.sort.join("\n  ")}
          OUTPUT

        puts <<~OUTPUT if schools_with_future_sessions[:closing].any?

URNs of schools that will be closing, with future sessions:
  #{schools_with_future_sessions[:closing].to_a.sort.join("\n  ")}
          OUTPUT
      end

      private

      def check_for_school_closure(row, school_set)
        urn = row["URN"]
        new_status = row["EstablishmentStatus (name)"]

        if new_status == "Closed"
          school_set[:closed] << urn
        elsif new_status == "Open, but proposed to close"
          school_set[:closing] << urn
        end
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "check-import", GIAS::CheckImport
  end
end
