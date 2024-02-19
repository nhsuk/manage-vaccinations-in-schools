desc "Get performance stats"
task :performance, [] => :environment do |_task, _args|
  puts "Copy and paste the following into Slack:"
  puts ""
  puts "**:rocket: Pilot performance stats – #{Time.zone.now.to_fs(:nhsuk_date_day_of_week)}**"

  teams = Team.all - Team.where(name: "Team MAVIS")
  teams.each do |team|
    puts ""
    puts ""
    puts "*:health_worker: #{team.name}*"

    puts "*Active users: #{team.users.recently_active.count}/#{team.users.count}* users signed in in the last week"

    team.locations.each do |location|
      puts "*#{location.name}:*"
      puts "- :pencil: Expressions of interest: *#{location.registrations.count}* total, *#{
             location.registrations.where("created_at > ?", 1.week.ago).count
           }* in the last week"
    end
  end
end
