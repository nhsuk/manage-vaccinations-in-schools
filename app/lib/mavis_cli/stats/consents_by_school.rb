# frozen_string_literal: true

module MavisCLI
  module Stats
    class ConsentsBySchool < Dry::CLI::Command
      desc "Get consent statistics by school, for a specific programme or all programmes"

      option :ods_code, required: true, desc: "Filter by organisation ODS code"
      option :team_name, desc: "Filter by team name"
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
        team_name: nil,
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

        if team_name
          @teams = organisation.teams.where(name: team_name)
          if @teams.empty?
            warn "Could not find team '#{team_name}' for organisation '#{ods_code}'"
            return
          end
          puts "Filtering by team: #{@teams.map(&:name).join(", ")}"
        else
          @teams = organisation.teams
          puts "Filtering by all teams: #{@teams.map(&:name).join(", ")}"
        end

        @programmes =
          if programme
            [Programme.find_by(type: programme)]
          else
            @teams.includes(:programmes).flat_map(&:programmes).uniq(&:type)
          end

        @academic_year =
          academic_year ? academic_year.to_i : AcademicYear.current

        collect_data

        puts "\n--- Consent Responses by Date ---"
        puts "=" * 50
        puts by_date_csv

        puts "\n--- Consent Responses by Days Since Request ---"
        puts "=" * 50
        puts by_days_csv
      end

      def sessions
        @sessions ||=
          Session
            .joins(:session_programmes)
            .where(
              team: @teams,
              academic_year: @academic_year,
              session_programmes: {
                programme: @programmes
              }
            )
            .eager_load(:location)
      end

      def by_days_sessions
        sessions.where.not(send_consent_requests_at: nil)
      end

      def by_date_data
        collect_data if @by_date_data.blank?
        @by_date_data
      end

      def by_days_data
        collect_data if @by_days_data.blank?
        @by_days_data
      end

      def collect_data
        @by_date_data = {}
        @by_days_data = {}

        sessions.find_each do |session|
          session
            .patient_sessions
            .includes(patient: { consents: %i[consent_form parent] })
            .find_each do |patient_session|
              grouped_consents =
                @programmes.map do |programme|
                  ConsentGrouper.call(
                    patient_session.patient.consents,
                    programme_id: programme.id,
                    academic_year: AcademicYear.current
                  ).min_by(&:created_at)
                end

              consents = grouped_consents.compact

              consent = consents.min_by(&:created_at)
              next if consent.nil?

              if session.send_consent_requests_at.present?
                days =
                  (
                    consent.responded_at.to_date -
                      session.send_consent_requests_at
                  ).to_i

                @by_days_data[days] ||= {}
                @by_days_data[days][session.location] ||= 0
                @by_days_data[days][session.location] += 1
              end

              @by_date_data[consent.responded_at.to_date] ||= {}
              @by_date_data[consent.responded_at.to_date][
                session.location
              ] ||= 0
              @by_date_data[consent.responded_at.to_date][session.location] += 1
            end
        end
      end

      def by_date_csv
        CSV.generate do |csv|
          csv << [""] + sessions.map { _1.location.name }
          csv << ["Cohort"] + sessions.map { _1.patients.count }

          by_date_data.keys.sort.each do |date|
            csv << [date.iso8601] +
              sessions.map { by_date_data[date].fetch(_1.location, 0) }
          end
        end
      end

      def by_days_csv
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
