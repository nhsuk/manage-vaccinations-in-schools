#frozen_string_literal: true

module MavisCLI
  module GIAS
    class CheckUpdate < Dry::CLI::Command
      desc "Check what changes will be introduced with a GIAS update"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/dfe-schools.zip",
             desc: "GIAS database file to use"
      def call(input_file:, **)
        MavisCLI.load_rails

        require "zip"

        existing_locations_with_future_sessions =
          Set.new(
            Location
              .joins(sessions: :session_dates)
              .where("session_dates.value >= ?", Time.zone.today)
              .pluck(:urn)
          )
        existing_locations = Set.new(Location.pluck(:urn))
        organisation_locations = Set.new(Location.joins(:team).pluck(:urn))

        closed_locations_with_future_sessions = Set.new
        closing_locations_with_future_sessions = Set.new
        closed_locations_without_future_sessions = Set.new
        closing_locations_without_future_sessions = Set.new
        Set.new
        new_locations = Set.new

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

            if urn.in?(existing_locations_with_future_sessions)
              if new_status == "Closed"
                closed_locations_with_future_sessions << urn
              elsif new_status == "Open, but proposed to close"
                closing_locations_with_future_sessions << urn
              end
            elsif urn.in?(organisation_locations)
              if new_status == "Closed"
                closed_locations_without_future_sessions << urn
              elsif new_status == "Open, but proposed to close"
                closing_locations_without_future_sessions << urn
              end
            elsif !urn.in?(existing_locations) &&
                  new_status.in?(["Open", "Open, but proposed to close"])
              new_locations << urn
            end
          end
        end

        closed_locations_count =
          closed_locations_without_future_sessions.count +
            closed_locations_with_future_sessions.count
        closing_locations_count =
          closing_locations_without_future_sessions.count +
            closing_locations_with_future_sessions.count

        closed_locations_with_future_sessions_pct =
          closed_locations_with_future_sessions.count.to_f /
            existing_locations_with_future_sessions.count

        closing_locations_with_future_sessions_pct =
          closing_locations_with_future_sessions.count.to_f /
            existing_locations_with_future_sessions.count

        puts <<~OUTPUT
                  New locations (total): #{new_locations.count}
               Closed locations (total): #{closed_locations_count}
Proposed to be closed locations (total): #{closing_locations_count}

 Existing locations with future sessions: #{existing_locations_with_future_sessions.count}
               That are closed in import: #{closed_locations_with_future_sessions.count} (#{closed_locations_with_future_sessions_pct * 100}%)
That are proposed to be closed in import: #{closing_locations_with_future_sessions.count} (#{closing_locations_with_future_sessions_pct * 100}%)
        OUTPUT

        puts <<~OUTPUT if closed_locations_with_future_sessions.any?

URNs of closed locations with future sessions:
  #{closed_locations_with_future_sessions.to_a.sort.join("\n  ")}
          OUTPUT
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "check-update", GIAS::CheckUpdate
  end
end
