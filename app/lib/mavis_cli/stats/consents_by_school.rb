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

        organisation = find_organisation(ods_code)
        return unless organisation

        teams = find_teams(organisation, workgroup, ods_code)
        return unless teams

        programmes = find_programmes(teams, programme)
        academic_year_value = academic_year&.to_i || AcademicYear.current

        @service =
          ::Stats::ConsentsBySchool.new(
            teams: teams,
            programmes: programmes,
            academic_year: academic_year_value
          )

        results = @service.call

        output_results(results)
      end

      private

      def find_organisation(ods_code)
        organisation = Organisation.find_by(ods_code:)
        if organisation.nil?
          warn "Could not find organisation with ODS code '#{ods_code}'"
          return nil
        end
        puts "Filtering by organisation: #{ods_code}"
        organisation
      end

      def find_teams(organisation, workgroup, ods_code)
        if workgroup
          teams = organisation.teams.where(workgroup:)
          if teams.empty?
            warn "Could not find team '#{workgroup}' for organisation '#{ods_code}'"
            return nil
          end
          puts "Filtering by team: #{teams.map(&:workgroup).join(", ")}"
        else
          teams = organisation.teams
          puts "Filtering by all teams: #{teams.map(&:workgroup).join(", ")}"
        end
        teams
      end

      def find_programmes(teams, programme)
        if programme
          [Programme.find_by(type: programme)]
        else
          teams.includes(:programmes).flat_map(&:programmes).uniq(&:type)
        end
      end

      def output_results(results)
        puts "\n--- Consent Responses by Date ---"
        puts "=" * 50
        puts generate_by_date_csv(results)

        puts "\n--- Consent Responses by Days Since Request ---"
        puts "=" * 50
        puts generate_by_days_csv(results)
      end

      def generate_by_date_csv(results)
        sessions = results[:sessions]
        by_date_data = results[:by_date]
        columns = build_columns(sessions)

        CSV.generate do |csv|
          csv << build_header_row(columns)
          csv << build_programme_row(columns)
          csv << build_cohort_row(sessions, columns)

          by_date_data.keys.sort.each do |date|
            csv << build_data_row(date.iso8601, columns, by_date_data[date])
          end
        end
      end

      def generate_by_days_csv(results)
        sessions = results[:sessions]
        by_days_data = results[:by_days]
        columns = build_columns(sessions)

        CSV.generate do |csv|
          csv << build_header_row(columns)
          csv << build_programme_row(columns)
          csv << build_cohort_row(sessions, columns)
          csv << build_consent_date_row(sessions, columns)
          csv << build_first_session_date_row(sessions, columns)

          by_days_data.keys.sort.each do |day|
            csv << build_data_row(day, columns, by_days_data[day])
          end
        end
      end

      def build_header_row(columns)
        [""] + columns.map { |location, _| location.name }
      end

      def build_programme_row(columns)
        ["Programme"] + columns.map { |_, programme| programme.type }
      end

      def build_cohort_row(sessions, columns)
        ["Cohort"] +
          columns.map do |location, programme|
            cohort_count_for_column(sessions, location, programme)
          end
      end

      def build_consent_date_row(sessions, columns)
        ["Date consent requests sent"] +
          columns.map do |location, programme|
            session = find_session_for_column(sessions, location, programme)
            next nil unless session

            @service
              .send(:first_consent_notification_date, session, programme)
              &.to_date
              &.iso8601
          end
      end

      def build_first_session_date_row(sessions, columns)
        ["First session date"] +
          columns.map do |location, programme|
            session = find_session_for_column(sessions, location, programme)
            next nil unless session

            @service
              .send(:first_session_date_after_consent, session, programme)
              &.to_date
              &.iso8601
          end
      end

      def build_data_row(label, columns, data)
        [label] +
          columns.map do |location, programme|
            data.fetch([location.id, programme.id], 0)
          end
      end

      def find_session_for_column(sessions, location, programme)
        sessions.find do |session|
          session.location == location &&
            session.session_programmes.map(&:programme).include?(programme)
        end
      end

      def cohort_count_for_column(sessions, location, programme)
        sessions
          .select do |s|
            s.location == location &&
              s.session_programmes.map(&:programme).include?(programme)
          end
          .sum do |session|
            ConsentNotification
              .request
              .joins(:programmes)
              .where(
                patient_id: session.patients.pluck(:id),
                programmes: {
                  id: programme.id
                }
              )
              .distinct
              .count(:patient_id)
          end
      end

      def build_columns(sessions)
        sessions
          .flat_map do |session|
            session.session_programmes.map do |sp|
              [session.location, sp.programme]
            end
          end
          .uniq
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "consents-by-school", Stats::ConsentsBySchool
  end
end
