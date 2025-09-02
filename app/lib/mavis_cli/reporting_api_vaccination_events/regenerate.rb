# frozen_string_literal: true

module MavisCLI
  module ReportingAPIVaccinationEvents
    class Regenerate < Dry::CLI::Command
      desc "Re-generate ReportingAPI Vaccination Events"
      argument :min_datetime,
               desc:
                 "Only regenerate for vaccination records created after this datetime (use ISO8601 format)",
               optional: true,
               aliases: %w[--from -f],
               default: nil

      def call(min_datetime: Time.current - 2.years, **)
        MavisCLI.load_rails

        records = VaccinationRecord.where("created_at > ?", min_datetime)
        progress_bar = MavisCLI.progress_bar(records.count)

        records.find_each do |vr|
          vr.create_or_update_reporting_api_vaccination_event
          progress_bar.increment
        end
      end
    end
  end

  register "reporting-api-vaccination-events" do |prefix|
    prefix.register "regenerate", ReportingAPIVaccinationEvents::Regenerate
  end
end
