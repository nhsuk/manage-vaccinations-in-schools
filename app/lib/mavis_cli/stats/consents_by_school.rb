# frozen_string_literal: true

module MavisCLI
  module Stats
    class ConsentsBySchool < Dry::CLI::Command
      desc "Get consent statistics by school, for a specific programme or all programmes"

      option :ods_code, required: true, desc: "Filter by organisation ODS code"
      option :workgroup, desc: "Filter by team workgroup"
      option :programme,
             required: false,
             values: %w[flu hpv menacwy td_ipv],
             desc:
               "Filter by specific programme type (if not provided, all programmes will be processed)"
      option :academic_year,
             type: :integer,
             desc:
               "Academic year to consider for stats (default: current academic year)"

      def call(
        programme: nil,
        ods_code: nil,
        workgroup: nil,
        academic_year: nil,
        **
      )
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code: ods_code)
        if organisation.nil?
          warn "Could not find organisation with ODS code '#{ods_code}'"
          return
        end
        puts "Filtering by organisation: #{organisation.ods_code}"

        if workgroup
          teams = organisation.teams.where(workgroup: workgroup)
          if teams.empty?
            warn "Could not find team '#{workgroup}' for organisation '#{ods_code}'"
            return
          end
          puts "Filtering by team: #{teams.map(&:workgroup).join(", ")}"
        else
          teams = organisation.teams
          puts "Filtering by all teams: #{teams.map(&:workgroup).join(", ")}"
        end

        programmes =
          if programme
            [Programme.find_by(type: programme)]
          else
            teams.includes(:programmes).flat_map(&:programmes).uniq(&:type)
          end

        academic_year_value =
          academic_year ? academic_year.to_i : AcademicYear.current

        service =
          ::Stats::ConsentsBySchool.new(
            teams: teams,
            programmes: programmes,
            academic_year: academic_year_value
          )

        results = service.call

        puts "\n--- Consent Responses by Date ---"
        puts "=" * 50
        puts generate_by_date_csv(results)

        puts "\n--- Consent Responses by Days Since Request ---"
        puts "=" * 50
        puts generate_by_days_csv(results)
      end

      private

      def generate_by_date_csv(results)
        sessions = results[:sessions]
        by_date_data = results[:by_date]

        CSV.generate do |csv|
          csv << [""] + sessions.map { _1.location.name }
          csv << ["Cohort"] + sessions.map { _1.patients.count }

          by_date_data.keys.sort.each do |date|
            csv << [date.iso8601] +
              sessions.map { by_date_data[date].fetch(_1.location, 0) }
          end
        end
      end

      def generate_by_days_csv(results)
        by_days_sessions = results[:by_days_sessions]
        by_days_data = results[:by_days]

        CSV.generate do |csv|
          csv << [""] + by_days_sessions.map { _1.location.name }
          csv << ["Cohort"] + by_days_sessions.map { _1.patients.count }
          csv << ["Date consent requests sent"] +
            by_days_sessions.map(&:send_consent_requests_at).map(&:iso8601)

          by_days_data.keys.sort.each do |day|
            csv << [day] +
              by_days_sessions.map { by_days_data[day].fetch(_1.location, 0) }
          end
        end
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "consents-by-school", Stats::ConsentsBySchool
  end
end
