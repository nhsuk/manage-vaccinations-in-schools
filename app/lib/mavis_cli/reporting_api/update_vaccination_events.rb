# frozen_string_literal: true

module MavisCLI
  module ReportingAPI
    class UpdateVaccinationEvents < Dry::CLI::Command
      desc <<-DESC
      Update ReportingAPI Vaccination Events for all VaccinationRecords created after a given DateTime.
      DateTimes can be given in any format parsable by Time.parse.
      Defaults to one year ago.
      DESC

      option :from,
             desc: "Only consider vaccination records created after this time",
             type: :string,
             optional: true,
             aliases: %w[--from],
             default: nil

      def call(from: nil, **)
        MavisCLI.load_rails

        min_datetime = from ? Time.zone.parse(from) : (Time.zone.now - 1.year)

        vaccination_records =
          VaccinationRecord.where("created_at > ?", min_datetime)
        puts "#{vaccination_records.count} VaccinationRecords created since #{min_datetime.iso8601}"
        if vaccination_records.exists?
          puts "Updating VaccinationEvents"
          progress_bar = MavisCLI.progress_bar(vaccination_records.count + 1)

          vaccination_records.find_each do |vaccination_record|
            vaccination_record.create_or_update_reporting_api_vaccination_event!
            progress_bar.increment
          end
        else
          puts "Nothing to do"
        end
      end
    end
  end

  register "reporting-api" do |prefix|
    prefix.register "update-vaccination-events",
                    ReportingAPI::UpdateVaccinationEvents
  end
end
