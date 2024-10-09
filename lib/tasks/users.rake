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
      registration = prompt_user_for "Enter registration:"
    elsif args.to_a.size == 6
      email = args[:email]
      password = args[:password]
      given_name = args[:given_name]
      family_name = args[:family_name]
      team_ods_code = args[:team_ods_code]
      registration = args[:registration]
    elsif args.to_a.size != 6
      raise "Expected 6 arguments got #{args.to_a.size}"
    end

    team = Team.find_by!(ods_code: team_ods_code)

    user =
      User.create!(email:, password:, family_name:, given_name:, registration:)
    user.teams << team

    puts "User #{given_name} #{family_name} (#{email}) added to team #{team.name}."
  end

  desc "Create a new user and add them to a team, sending their password via email."
  task :create_securely,
       %i[email given_name family_name team_ods_code registration] =>
         :environment do |_task, args|
    include TaskHelpers

    password = SecureRandom.uuid

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter user email:", required: true
      given_name = prompt_user_for "Enter given name:", required: true
      family_name = prompt_user_for "Enter family name:", required: true
      team_ods_code = prompt_user_for "Enter team ODS code:", required: true
      registration = prompt_user_for "Enter registration:"
    elsif args.to_a.size == 5
      email = args[:email]
      given_name = args[:given_name]
      family_name = args[:family_name]
      team_ods_code = args[:team_ods_code]
      registration = args[:registration]
    elsif args.to_a.size != 5
      raise "Expected 5 arguments got #{args.to_a.size}"
    end

    team = Team.find_by!(ods_code: team_ods_code)

    user =
      User.create!(email:, password:, family_name:, given_name:, registration:)
    user.teams << team

    puts "User #{full_name} (#{email}) added to team #{team.name}."

    user.send_reset_password_instructions
    puts "Password reset instructions sent."
  end
end
