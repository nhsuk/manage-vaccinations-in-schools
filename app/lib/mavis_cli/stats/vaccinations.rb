# frozen_string_literal: true

module MavisCLI
  module Stats
    class Vaccinations < Dry::CLI::Command
      desc "Get number of vaccinations recorded in Mavis by programme and outcome"

      option :since_date,
             desc: "Start date (YYYY-MM-DD format). Defaults to service start"
      option :until_date, desc: "End date (YYYY-MM-DD format). Defaults to now"
      option :format,
             default: "table",
             values: %w[table json csv],
             desc: "Output format"
      option :programme,
             values: %w[flu hpv menacwy td_ipv],
             desc: "Filter by specific programme type"
      option :outcome,
             values: %w[
               administered
               not_well
               already_had
               contraindications
               absent_from_session
               refused
             ],
             desc: "Filter by specific outcome"
      option :ods_code, desc: "Filter by organisation ODS code"
      option :workgroup, desc: "Filter by team workgroup"

      def call(
        since_date: nil,
        until_date: nil,
        format: "table",
        programme: nil,
        outcome: nil,
        ods_code: nil,
        workgroup: nil,
        **
      )
        MavisCLI.load_rails

        teams = resolve_teams(ods_code, workgroup)
        return unless teams

        # programme = Programme.find_by(type: programme) if programme

        service =
          ::Stats::Vaccinations.new(
            since_date:,
            until_date:,
            programme:,
            outcome:,
            teams:
          )

        results = service.call

        case format
        when "json"
          puts results.to_json
        when "csv"
          puts generate_csv(results)
        else
          puts generate_table(
                 results,
                 since_date,
                 binding.local_variable_get(:until_date)
               )
        end
      end

      private

      def resolve_teams(ods_code, workgroup)
        if ods_code
          organisation = Organisation.find_by(ods_code:)
          if organisation.nil?
            warn "Could not find organisation with ODS code '#{ods_code}'"
            return
          end

          if workgroup
            teams = organisation.teams.where(workgroup:)
            if teams.empty?
              warn "Could not find team '#{workgroup}' for organisation '#{ods_code}'"
              return
            end
            puts "Filtering by organisation: #{organisation.ods_code}"
            puts "Filtering by team: #{teams.map(&:workgroup).join(", ")}"
          else
            puts "Filtering by organisation: #{organisation.ods_code}"
            teams = organisation.teams
            puts "Filtering by all teams: #{teams.map(&:workgroup).sort.join(", ")}"
          end
          teams
        elsif workgroup
          team = Team.find_by(workgroup:)
          if team.nil?
            warn "Could not find team '#{workgroup}'"
            return nil
          end
          puts "Filtering by team: #{team.workgroup}"
          [team]
        else
          teams = Team.all
          puts "Filtering by all teams: #{teams.map(&:workgroup).sort.join(", ")}"
          teams
        end
      end

      def generate_csv(results)
        csv_output = ["Programme,Outcome,Count"]
        results.each do |programme, outcomes|
          outcomes.each do |outcome, count|
            csv_output << "#{programme},#{outcome},#{count}"
          end
        end
        csv_output.join("\n")
      end

      def generate_table(results, since_date, until_date)
        title = build_table_title(since_date, until_date)
        output = [title, "=" * title.length, ""]

        results.each do |programme, outcomes|
          output << "#{programme}:"
          output << "  #{"Outcome".ljust(20)} | Count"
          output << "  #{"-" * 20} | -----"

          outcomes.each do |outcome, count|
            output << "  #{outcome.ljust(20)} | #{count}"
          end

          output << "  Total: #{outcomes.values.sum}"
          output << ""
        end

        grand_total = results.values.map(&:values).flatten.sum
        output << "Grand Total: #{grand_total}"

        output.join("\n")
      end

      def build_table_title(since_date, until_date)
        title = "Vaccination Counts by Programme and Outcome"

        date_parts = []
        date_parts << "from #{since_date}" if since_date
        date_parts << "until #{until_date}" if until_date

        title += " (#{date_parts.join(", ")})" unless date_parts.empty?
        title
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "vaccinations", Stats::Vaccinations
  end
end
