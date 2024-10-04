# frozen_string_literal: true

require_relative "../task_helpers"

desc <<-DESC
  Add a new user

  Usage:
    rake add_new_user # Complete the prompts
    rake add_new_user[email,password,given_name,family_name,team_id,registration]
DESC
task :add_new_user,
     %i[email password given_name family_name team_id registration] =>
       :environment do |_task, args|
  include TaskHelpers

  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    email = prompt_user_for "Enter email:", required: true
    password = prompt_user_for "Enter password:", required: true
    given_name = prompt_user_for "Enter given name:", required: true
    family_name = prompt_user_for "Enter family name:", required: true
    team_id = prompt_user_for "Enter team ID:", required: true
    registration = prompt_user_for "Enter registration:"
  elsif args.to_a.size == 6
    email = args[:email]
    password = args[:password]
    given_name = args[:given_name]
    family_name = args[:family_name]
    team_id = args[:team_id]
    registration = args[:registration]
  elsif args.to_a.size != 6
    raise "Expected 5 arguments got #{args.to_a.size}"
  end

  user =
    User.create!(email:, password:, family_name:, given_name:, registration:)
  user.teams << Team.find(team_id)

  puts "User #{given_name} #{family_name} (#{email}) added to team #{team_id}."
end
