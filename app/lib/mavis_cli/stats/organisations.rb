# frozen_string_literal: true

module MavisCLI
  module Stats
    class Organisations < Dry::CLI::Command
      desc "Get statistics for organisations including cohorts, schools, comms, consents and vaccination rates"

      option :ods_code, required: true, desc: "Filter by organisation ODS code"
      option :team_name, desc: "Filter by team name"
      option :format,
             default: "table",
             values: %w[table json],
             desc: "Output format"
      option :programme,
             values: %w[flu hpv menacwy td_ipv],
             desc: "Filter by specific programme type"
      option :academic_year,
             type: :integer,
             desc:
               "Academic year to consider for stats (default: current academic year)"

      def call(
        ods_code: nil,
        team_name: nil,
        format: "table",
        programme: nil,
        academic_year: nil,
        **
      )
        MavisCLI.load_rails

        organisation, teams =
          resolve_organisation_and_teams(ods_code, team_name)
        return unless organisation && teams

        programmes = resolve_programmes(teams, programme)
        resolved_academic_year =
          academic_year ? academic_year.to_i : AcademicYear.current

        service =
          ::Stats::Organisations.new(
            organisation: organisation,
            teams: teams,
            programmes: programmes,
            academic_year: resolved_academic_year
          )

        results = service.call

        case format
        when "json"
          puts results.to_json
        else
          output_table(results, programme, resolved_academic_year)
        end
      end

      private

      def resolve_organisation_and_teams(ods_code, team_name)
        organisation = Organisation.find_by(ods_code: ods_code)
        if organisation.nil?
          warn "Could not find organisation with ODS code '#{ods_code}'"
          return nil, nil
        end
        puts "Filtering by organisation: #{organisation.ods_code}"

        if team_name
          teams = organisation.teams.where(name: team_name)
          if teams.empty?
            warn "Could not find team '#{team_name}' for organisation '#{ods_code}'"
            return nil, nil
          end
          puts "Filtering by team: #{teams.map(&:name).join(", ")}"
        else
          teams = organisation.teams
          puts "Filtering by all teams: #{teams.map(&:name).join(", ")}"
        end

        [organisation, teams]
      end

      def resolve_programmes(teams, programme)
        if programme
          [Programme.find_by(type: programme)]
        else
          teams.includes(:programmes).flat_map(&:programmes).uniq(&:type)
        end
      end

      def output_table(results, programme_filter, academic_year)
        date_range = academic_year.to_academic_year_date_range
        start_date = date_range.first.strftime("%-d %B %Y")
        end_date = date_range.last.strftime("%-d %B %Y")
        title = "Organisation Statistics from #{start_date} to #{end_date}"
        title += " (#{programme_filter} programme)" if programme_filter
        puts title
        puts "=" * title.length
        puts

        org_header = "Organisation #{results[:ods_code]}"
        org_header += "\nTeams: #{results[:team_names]}"
        puts org_header
        puts "-" * org_header.length
        puts

        results[:programme_stats].each do |programme_stat|
          puts "Programme: #{programme_stat[:programme_name]}"
          puts "=" * 50

          output_cohort_and_schools(programme_stat)
          output_communications(programme_stat)
          output_consents(programme_stat)
          output_vaccinations(programme_stat)

          puts "-" * 50
          puts
        end

        puts "=" * 80
        puts
      end

      def output_cohort_and_schools(programme_stat)
        puts "Cohort & Schools:"
        puts "  Total schools: #{programme_stat[:school_total]}"
        cohort_total = programme_stat[:cohort_total][:total]
        puts "  Total eligible patients: #{cohort_total}"
        programme_stat[:cohort_total][:years].each do |year, year_count|
          puts "    Year #{year}: #{year_count}"
        end
        puts
      end

      def output_communications(programme_stat)
        puts "Communications:"
        comms = programme_stat[:comms_stats]
        puts "  Schools involved in consent notifications: #{comms[:schools_involved]}"
        puts "  Patients who received consent notifications: #{comms[:patients_with_comms]}"
        puts "    of these, consent requests: #{comms[:patients_with_requests]}"
        puts "    of these, consent reminders: #{comms[:patients_with_reminders]}"
        puts
      end

      def output_consents(programme_stat)
        puts "Consents:"
        consent = programme_stat[:consent_stats]
        puts "  Total consent responses received: #{consent[:total_consents]}"
        no_response = consent[:patients_with_no_response]
        puts "  Patients with no response: #{no_response[:total]}"
        puts "    of these, contacted: #{no_response[:contacted]}"
        puts "  Patients with status 'given': #{consent[:patients_with_response_given]}"
        puts "  Patients with status 'refused': #{consent[:patients_with_response_refused]}"
        puts "  Patients with status 'conflicting': #{consent[:patients_with_response_conflicting]}"
        puts
      end

      def output_vaccinations(programme_stat)
        puts "Vaccinations:"
        vacc = programme_stat[:vaccination_stats]
        puts "  Coverage: #{vacc[:coverage_count]} (#{vacc[:coverage_percentage]}%)"
        puts "  Vaccinated in Mavis: #{vacc[:vaccinated_in_mavis_count]}"
        puts
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "organisations", Stats::Organisations
  end
end
