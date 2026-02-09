# frozen_string_literal: true

module MavisCLI
  module Teams
    class SetNationalReportingCutOffDate < Dry::CLI::Command
      desc "Set or clear the national reporting cut-off date for a national reporting team"

      option :workgroup, desc: "The workgroup of the national reporting team"
      option :date, desc: "Cut-off date in YYYY-MM-DD format"
      option :clear, type: :boolean, desc: "Clear the cut-off date (set to nil)"

      def call(workgroup: nil, date: nil, clear: false, **)
        MavisCLI.load_rails

        raise ArgumentError, "workgroup is required" if workgroup.blank?
        if clear && date.present?
          raise ArgumentError, "Provide either --date or --clear, not both"
        end
        if !clear && date.blank?
          raise ArgumentError, "Either --date or --clear is required"
        end

        cut_off_date = nil
        unless clear
          begin
            cut_off_date = Date.parse(date)
          rescue ArgumentError
            raise ArgumentError,
                  "Invalid date format: #{date} (expected YYYY-MM-DD)"
          end
        end

        team = Team.find_by(workgroup:)
        raise ArgumentError, "Team not found: #{workgroup}" if team.nil?
        unless team.has_national_reporting_access?
          raise ArgumentError,
                "Team #{workgroup} is not a national reporting team"
        end

        team.update!(national_reporting_cut_off_date: cut_off_date)
        if clear
          puts(
            "Cleared national_reporting_cut_off_date for #{team.name} (#{team.workgroup})"
          )
        else
          puts(
            "Set national_reporting_cut_off_date for #{team.name} (#{team.workgroup}) to #{cut_off_date}"
          )
        end
      end
    end
  end

  register "teams" do |prefix|
    prefix.register(
      "set-national-reporting-cut-off-date",
      Teams::SetNationalReportingCutOffDate
    )
  end
end
