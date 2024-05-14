desc "Get performance stats"
task :performance, [] => :environment do |_task, _args|
  include ActionView::Helpers::TextHelper

  puts "Copy and paste the following into Slack:"
  puts ""
  puts ":chart_with_upwards_trend: *PILOT PERFORMANCE* _#{Time.zone.now.to_fs(:nhsuk_date_day_of_week)}_"
  puts ""

  teams = Team.all - Team.where(name: "Team MAVIS")

  patients_total = Patient.where(location: teams.map(&:locations).flatten).count
  puts "#{patients_total} *Patients in cohort (total)*"

  consent_forms_total =
    ConsentForm
      .joins(:team)
      .where(session: { campaigns: { team: teams } })
      .and(ConsentForm.where.not(recorded_at: nil))
      .count
  puts "#{consent_forms_total} *Consents returned (total)*"

  vaccination_records_total =
    VaccinationRecord
      .joins(:team)
      .where(session: { campaigns: { team: teams } })
      .and(VaccinationRecord.where.not(recorded_at: nil))
      .count
  puts "#{vaccination_records_total} *Vaccination records (total)*"

  teams.each do |team|
    puts ""
    puts ":wavy_dash::wavy_dash::wavy_dash::wavy_dash::wavy_dash::wavy_dash:" \
           ":wavy_dash::wavy_dash::wavy_dash::wavy_dash:"
    puts "*:hospital: #{team.name}*"

    users = "#{team.users.recently_active.count}/#{team.users.count}"
    puts ":busts_in_silhouette: Active users: #{users} users signed in in the last week"

    team.campaigns.first.sessions.active.each do |session|
      puts ""
      puts ":school: *#{session.location.name}*"

      @counts =
        SessionStats.new(patient_sessions: session.patient_sessions, session:)
      puts "    - #{pluralize(session.location.patients.count, "child")} in cohort :racing_car:"
      puts "        - #{pluralize(@counts[:with_consent_given], "child")} with consent given :white_check_mark:"
      puts "            - #{pluralize(@counts[:ready_to_vaccinate], "child")} ready to vaccinate :syringe:"
      puts "        - #{pluralize(@counts[:with_consent_refused], "child")} with consent refused :x:"
      puts "        - #{pluralize(@counts[:without_a_response], "child")} without a response :crying_cat_face:"
      unmatched_responses = pluralize(@counts[:unmatched_responses], "response")
      puts "    - #{unmatched_responses} need matching with records in the cohort :shrug:"
    end
  end
end

# 1000 => ":one::zero::zero::zero:"
def emoji_count(number)
  number.to_s.split("").map { ":#{I18n.t("number.#{_1}")}:" }.join
end
