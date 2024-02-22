desc "Get performance stats"
task :performance, [] => :environment do |_task, _args|
  puts "Copy and paste the following into Slack:"
  puts ""
  puts ":chart_with_upwards_trend: *PILOT PERFORMANCE* _#{Time.zone.now.to_fs(:nhsuk_date_day_of_week)}_"
  puts ""
  puts "#{emoji_count(Registration.count)} *Expressions of interest (total)*"
  puts ""

  teams = Team.all - Team.where(name: "Team MAVIS")
  teams.each do |team|
    puts ""
    puts ""
    puts "*:hospital: #{team.name}*"

    users = "#{team.users.recently_active.count}/#{team.users.count}"
    puts ":busts_in_silhouette: Active users: #{users} users signed in in the last week"

    puts ":pencil: Expressions of interest"
    team.locations.each do |location|
      puts "- *#{location.name}:* #{location.registrations.count}"
    end
  end
end

# 1000 => ":one::zero::zero::zero:"
def emoji_count(number)
  number.to_s.split("").map { ":#{I18n.t("number.#{_1}")}:" }.join
end
