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

        existing_schools_with_future_sessions =
          Set.new(
            Location
              .school
              .joins(sessions: :session_dates)
              .where("session_dates.value >= ?", Time.zone.today)
              .pluck(:urn)
          )
        existing_schools = Set.new(Location.school.pluck(:urn))
        organisation_schools =
          Set.new(Location.school.joins(:subteam).pluck(:urn))

        closed_schools_with_future_sessions = Set.new
        closing_schools_with_future_sessions = Set.new
        closed_schools_without_future_sessions = Set.new
        closing_schools_without_future_sessions = Set.new
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

            if urn.in?(existing_schools_with_future_sessions)
              if new_status == "Closed"
                closed_schools_with_future_sessions << urn
              elsif new_status == "Open, but proposed to close"
                closing_schools_with_future_sessions << urn
              end
            elsif urn.in?(organisation_schools)
              if new_status == "Closed"
                closed_schools_without_future_sessions << urn
              elsif new_status == "Open, but proposed to close"
                closing_schools_without_future_sessions << urn
              end
            elsif !urn.in?(existing_schools) &&
                  new_status.in?(["Open", "Open, but proposed to close"])
              new_schools << urn
            end
          end
        end

        closed_schools_count =
          closed_schools_without_future_sessions.count +
            closed_schools_with_future_sessions.count
        closing_schools_count =
          closing_schools_without_future_sessions.count +
            closing_schools_with_future_sessions.count

        closed_schools_with_future_sessions_pct =
          closed_schools_with_future_sessions.count.to_f /
            existing_schools_with_future_sessions.count

        closing_schools_with_future_sessions_pct =
          closing_schools_with_future_sessions.count.to_f /
            existing_schools_with_future_sessions.count

        puts <<~OUTPUT
                  New schools (total): #{new_schools.count}
               Closed schools (total): #{closed_schools_count}
Proposed to be closed schools (total): #{closing_schools_count}

 Existing schools with future sessions: #{existing_schools_with_future_sessions.count}
               That are closed in import: #{closed_schools_with_future_sessions.count} (#{closed_schools_with_future_sessions_pct * 100}%)
That are proposed to be closed in import: #{closing_schools_with_future_sessions.count} (#{closing_schools_with_future_sessions_pct * 100}%)
        OUTPUT

        puts <<~OUTPUT if closed_schools_with_future_sessions.any?

URNs of closed schools with future sessions:
  #{closed_schools_with_future_sessions.to_a.sort.join("\n  ")}
          OUTPUT
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "check-import", GIAS::CheckImport
  end
end
