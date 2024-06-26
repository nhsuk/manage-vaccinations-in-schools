# frozen_string_literal: true

require_relative "../task_helpers"

desc <<-DESC
  Add a new user with a secured password

  The user's password will be randomly generated and not displayed. The user
  will need to reset their password to use the account.

  Usage:
    rake add_new_user_securely # Complete the prompts
    rake add_new_user_securely[email,full_name,team_id,registration]
DESC
task :add_new_user_securely,
     %i[email full_name team_id registration] => :environment do |_task, args|
  include TaskHelpers

  password = SecureRandom.uuid

  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    email = prompt_user_for "Enter user email:", required: true
    full_name = prompt_user_for "Enter full name:", required: true
    team_id = prompt_user_for "Enter team ID:", required: true
    registration = prompt_user_for "Enter registration:"
  elsif args.to_a.size == 4
    email = args[:email]
    full_name = args[:full_name]
    team_id = args[:team_id]
    registration = args[:registration]
  elsif args.to_a.size != 4
    raise "Expected 4 arguments got #{args.to_a.size}"
  end

  user = User.create!(email:, password:, full_name:, registration:)
  user.teams << Team.find(team_id)

  puts "User #{full_name} (#{email}) added to team #{team_id}."

  user.send_reset_password_instructions
  puts "Password reset instructions sent."
end
