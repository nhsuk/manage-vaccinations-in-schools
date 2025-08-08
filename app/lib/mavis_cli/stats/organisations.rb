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

        @org = Organisation.find_by(ods_code:)
        if @org.nil?
          warn "Could not find organisation with ODS code '#{ods_code}'"
          return
        end
        puts "Filtering by organisation: #{@org.ods_code}"

        if team_name
          @teams = @org.teams.where(name: team_name)
          if @teams.empty?
            warn "Could not find team '#{team_name}' for organisation '#{ods_code}'"
            return
          end
          puts "Filtering by team: #{@teams.map(&:name).join(", ")}"
        else
          @teams = @org.teams
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

        @patients =
          Patient
            .joins(:teams)
            .where(teams: { id: @teams.select(:id) })
            .distinct

        results = [calculate_organisation_stats]

        case format
        when "json"
          puts results.to_json
        else
          output_table(results, programme)
        end
      end

      private

      def calculate_organisation_stats
        programme_stats =
          @programmes.map do |programme|
            {
              programme_name: programme.type,
              cohort_total: calculate_cohort_total(programme),
              school_total: calculate_school_total(programme),
              consent_stats: calculate_consent_stats(programme),
              comms_stats: calculate_consent_notifications_stats(programme),
              vaccination_stats: calculate_vaccination_stats(programme)
            }
          end

        {
          ods_code: @org.ods_code,
          team_names: @teams.map(&:name).join(", "),
          programme_stats: programme_stats
        }
      end

      def calculate_cohort_total(programme)
        @eligible_patients = get_eligible_patients(programme)

        by_year =
          @eligible_patients.group_by(&:year_group).transform_values(&:count)

        { total: @eligible_patients.count, years: by_year }
      end

      def calculate_school_total(programme)
        @teams
          .includes(:schools)
          .flat_map(&:schools)
          .uniq
          .select { |location| location.programmes.include?(programme) }
          .count
      end

      def calculate_consent_stats(programme)
        total_consents =
          Consent
            .joins(:team)
            .where(team: @teams)
            .where(programme: programme, academic_year: @academic_year)
            .distinct
            .count

        patients_with_no_response =
          @eligible_patients.has_consent_status(
            :no_response,
            programme: programme,
            academic_year: @academic_year
          )

        patients_with_response_given =
          @eligible_patients.has_consent_status(
            :given,
            programme: programme,
            academic_year: @academic_year
          )

        patients_with_response_refused =
          @eligible_patients.has_consent_status(
            :refused,
            programme: programme,
            academic_year: @academic_year
          )

        patients_with_response_conflicting =
          @eligible_patients.has_consent_status(
            :conflicts,
            programme: programme,
            academic_year: @academic_year
          )

        no_response_but_contacted =
          patients_with_no_response.joins(:consent_notifications)

        {
          total_consents: total_consents,
          patients_with_no_response: {
            total: patients_with_no_response.count,
            contacted: no_response_but_contacted.count
          },
          patients_with_response_given: patients_with_response_given.count,
          patients_with_response_refused: patients_with_response_refused.count,
          patients_with_response_conflicting:
            patients_with_response_conflicting.count
        }
      end

      def calculate_consent_notifications_stats(programme)
        comms =
          ConsentNotification
            .joins(session: :team)
            .where(sessions: { team: @teams })
            .where(patient_id: @eligible_patients.map(&:id))
            .where(sessions: { academic_year: @academic_year })
            .has_programme(programme)

        initial_requests = comms.request
        reminders = comms.reminder

        schools_involved =
          comms.joins(:session).distinct.count(:"sessions.location_id")

        patients_with_comms = comms.distinct.count(:patient_id)
        patients_with_requests = initial_requests.distinct.count(:patient_id)
        patients_with_reminders = reminders.distinct.count(:patient_id)

        {
          schools_involved: schools_involved,
          patients_with_comms: patients_with_comms,
          patients_with_requests: patients_with_requests,
          patients_with_reminders: patients_with_reminders
        }
      end

      def calculate_vaccination_stats(programme)
        vaccinated_patients =
          @eligible_patients.has_vaccination_status(
            :vaccinated,
            programme: programme,
            academic_year: @academic_year
          )

        coverage_count = vaccinated_patients.count

        vaccinated_in_mavis_count =
          VaccinationRecord
            .recorded_in_service
            .for_academic_year(@academic_year)
            .where(patient_id: @eligible_patients.map(&:id))
            .where(programme_id: programme.id)
            .where(outcome: "administered")
            .distinct
            .count

        coverage_percentage =
          if @eligible_patients.count.positive?
            (coverage_count.to_f / @eligible_patients.count * 100).round(2)
          else
            0
          end

        {
          coverage_count: coverage_count,
          vaccinated_in_mavis_count: vaccinated_in_mavis_count,
          coverage_percentage: coverage_percentage
        }
      end

      def get_eligible_patients(programme)
        @patients.appear_in_programmes(
          [programme],
          academic_year: @academic_year
        )
      end

      def output_table(results, programme_filter)
        date_range = @academic_year.to_academic_year_date_range
        start_date = date_range.first.strftime("%-d %B %Y")
        end_date = date_range.last.strftime("%-d %B %Y")
        title = "Organisation Statistics from #{start_date} to #{end_date}"
        title += " (#{programme_filter} programme)" if programme_filter
        puts title
        puts "=" * title.length
        puts

        results.each do |stats|
          org_header = "Organisation #{stats[:ods_code]}"
          org_header += "\nTeams: #{stats[:team_names]}"
          puts org_header
          puts "-" * org_header.length
          puts

          stats[:programme_stats].each do |programme_stat|
            puts "Programme: #{programme_stat[:programme_name]}"
            puts "=" * 50

            puts "Cohort & Schools:"
            puts "  Total schools: #{programme_stat[:school_total]}"
            cohort_total = programme_stat[:cohort_total][:total]
            puts "  Total eligible patients: #{cohort_total}"
            programme_stat[:cohort_total][:years].each_key do |year|
              year_count = programme_stat[:cohort_total][:years][year]
              puts "    Year #{year}: #{year_count}"
            end
            puts

            puts "Communications:"
            comms = programme_stat[:comms_stats]
            puts "  Schools involved in consent notifications: #{comms[:schools_involved]}"
            puts "  Patients who received consent notifications: #{comms[:patients_with_comms]}"
            puts "    of these, consent requests: #{comms[:patients_with_requests]}"
            puts "    of these, consent reminders: #{comms[:patients_with_reminders]}"
            puts

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

            puts "Vaccinations:"
            vacc = programme_stat[:vaccination_stats]
            puts "  Coverage: #{vacc[:coverage_count]} (#{vacc[:coverage_percentage]}%)"
            puts "  Vaccinated in Mavis: #{vacc[:vaccinated_in_mavis_count]}"
            puts

            puts "-" * 50
            puts
          end

          puts "=" * 80
          puts
        end
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "organisations", Stats::Organisations
  end
end
