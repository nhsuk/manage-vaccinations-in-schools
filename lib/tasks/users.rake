# frozen_string_literal: true

require_relative "../task_helpers"

namespace :users do
  desc "Create a new user and add them to a team."
  task :create,
       %i[email password given_name family_name team_ods_code registration] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter email:", required: true
      password = prompt_user_for "Enter password:", required: true
      given_name = prompt_user_for "Enter given name:", required: true
      family_name = prompt_user_for "Enter family name:", required: true
      team_ods_code = prompt_user_for "Enter team ODS code:", required: true
    elsif args.to_a.size == 5
      email = args[:email]
      password = args[:password]
      given_name = args[:given_name]
      family_name = args[:family_name]
      team_ods_code = args[:team_ods_code]
    elsif args.to_a.size != 5
      raise "Expected 5 arguments got #{args.to_a.size}"
    end

    team = Team.find_by!(ods_code: team_ods_code)

    user = User.create!(email:, password:, family_name:, given_name:)
    user.teams << team

    puts "User #{given_name} #{family_name} (#{email}) added to team #{team.name}."
  end
end
