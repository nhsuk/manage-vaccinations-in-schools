desc "Get performance stats"
task :performance, [] => :environment do |_task, _args|
  include ActionView::Helpers::TextHelper

  puts "Copy and paste the following into Slack:"
  puts ""
  puts ":chart_with_upwards_trend: *PILOT PERFORMANCE* _#{Time.zone.now.to_fs(:nhsuk_date_day_of_week)}_"
  puts ""

  teams = Team.all - Team.where(name: "Team MAVIS")

  eoi_total = Registration.where(location: teams.map(&:locations).flatten).count
  puts "#{emoji_count(eoi_total)} *Expressions of interest (total)*"

  teams.each do |team|
    puts ""
    puts ""
    puts "*:hospital: #{team.name}*"

    users = "#{team.users.recently_active.count}/#{team.users.count}"
    puts ":busts_in_silhouette: Active users: #{users} users signed in in the last week"
    puts ""

    team.campaigns.first.sessions.active.each do |session|
      puts ":school: *#{session.location.name}*"
      puts ""

      puts "- :pencil: #{pluralize(session.location.registrations.count, "parents")} registered interest"

      @counts =
        SessionStats.new(patient_sessions: session.patient_sessions, session:)
      puts "- :white_check_mark: #{pluralize(@counts[:with_consent_given], "child")} with consent given"
      puts "- :x: #{pluralize(@counts[:with_consent_refused], "child")} with consent refused"
      puts "- :crying_cat_face: #{pluralize(@counts[:without_a_response], "child")} without a response"
      puts "- :shrug: #{pluralize(@counts[:unmatched_responses], "response")} need matching with records in the cohort"
      puts "- :syringe: #{pluralize(@counts[:ready_to_vaccinate], "child")} ready to vaccinate"
      puts ""
    end
  end
end

# 1000 => ":one::zero::zero::zero:"
def emoji_count(number)
  number.to_s.split("").map { ":#{I18n.t("number.#{_1}")}:" }.join
end
