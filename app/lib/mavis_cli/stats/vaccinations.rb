# frozen_string_literal: true

module MavisCLI
  module Stats
    class Vaccinations < Dry::CLI::Command
      desc "Get number of vaccinations recorded in Mavis by programme and outcome"

      option :since,
             desc: "Start date (YYYY-MM-DD format). Defaults to service start"
      option :until, desc: "End date (YYYY-MM-DD format). Defaults to now"
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
      option :team_name, desc: "Filter by team name"

      def call(
        since: nil,
        until: nil,
        format: "table",
        programme: nil,
        outcome: nil,
        ods_code: nil,
        team_name: nil,
        **
      )
        MavisCLI.load_rails

        vaccinations = VaccinationRecord.recorded_in_service

        if ods_code
          organisation = Organisation.find_by(ods_code: ods_code)
          if organisation.nil?
            warn "Could not find organisation with ODS code '#{ods_code}'"
            return
          end
          puts "Filtering by organisation: #{organisation.ods_code}"

          if team_name
            teams = organisation.teams.where(name: team_name)
            if teams.empty?
              warn "Could not find team '#{team_name}' for organisation '#{ods_code}'"
              return
            end
            puts "Filtering by team: #{teams.map(&:name).join(", ")}"
          else
            teams = organisation.teams
            puts "Filtering by all teams: #{teams.map(&:name).join(", ")}"
          end

          vaccinations =
            vaccinations.joins(:session).where(sessions: { team: teams })
        elsif team_name
          team = Team.find_by(name: team_name)
          if team.nil?
            warn "Could not find team '#{team_name}'"
            return
          end
          puts "Filtering by team: #{team.name}"
          vaccinations = vaccinations.joins(:session).where(sessions: { team: })
        end

        vaccinations =
          vaccinations.where(
            "vaccination_records.created_at >= ?",
            Date.parse(since)
          ) if since

        until_date = binding.local_variable_get(:until)
        vaccinations =
          vaccinations.where(
            "vaccination_records.created_at <= ?",
            Date.parse(until_date)
          ) if until_date

        if programme
          programme_record = Programme.find_by(type: programme)
          programme_type = programme
          vaccinations = vaccinations.where(programme_id: programme_record.id)
        end

        vaccinations = vaccinations.where(outcome: outcome) if outcome

        results = vaccinations.group(:programme_id, :outcome).count

        programme_results = {}

        if programme
          results.each do |(_programme_id, outcome_value), count|
            programme_results[programme_type] ||= {}
            programme_results[programme_type][outcome_value] = count
          end
        else
          programme_ids = results.keys.map(&:first).uniq
          programmes = Programme.where(id: programme_ids).index_by(&:id)

          results.each do |(programme_id, outcome_value), count|
            programme_record = programmes[programme_id]
            next unless programme_record
            programme_type = programme_record.type
            programme_results[programme_type] ||= {}
            programme_results[programme_type][outcome_value] = count
          end
        end

        case format
        when "json"
          puts programme_results.to_json
        when "csv"
          puts "Programme,Outcome,Count"
          programme_results.each do |programme, outcomes|
            outcomes.each do |outcome, count|
              puts "#{programme},#{outcome},#{count}"
            end
          end
        else
          title = build_table_title(since, until_date)
          output_table(title, programme_results)
        end
      end

      private

      def build_table_title(since, until_date)
        title = "Vaccination Counts by Programme and Outcome"

        date_parts = []
        date_parts << "from #{since}" if since
        date_parts << "until #{until_date}" if until_date

        title += " (#{date_parts.join(", ")})" unless date_parts.empty?
        title
      end

      def output_table(title, data)
        puts title
        puts "=" * title.length

        data.each do |programme, outcomes|
          puts "#{programme}:"
          puts "  #{"Outcome".ljust(20)} | Count"
          puts "  #{"-" * 20} | -----"
          outcomes.each do |outcome, count|
            puts "  #{outcome.ljust(20)} | #{count}"
          end
          puts "  Total: #{outcomes.values.sum}"
          puts
        end

        grand_total = data.values.map(&:values).flatten.sum
        puts "Grand Total: #{grand_total}"
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "vaccinations", Stats::Vaccinations
  end
end
