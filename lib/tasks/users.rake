# frozen_string_literal: true

require_relative "../task_helpers"

namespace :users do
  desc "Create a new user and add them to a team."
  task :create,
       %i[email password given_name family_name workgroup fallback_role] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter email:", required: true
      password = prompt_user_for "Enter password:", required: true
      given_name = prompt_user_for "Enter given name:", required: true
      family_name = prompt_user_for "Enter family name:", required: true
      workgroup = prompt_user_for "Enter team workgroup:", required: true
      fallback_role =
        prompt_user_for "Enter fallback role (nurse/admin):",
                        default: "nurse",
                        validate: ->(input) do
                          User.fallback_roles.key?(input.to_sym)
                        end
    elsif args.to_a.size.between?(5, 6)
      email = args[:email]
      password = args[:password]
      given_name = args[:given_name]
      family_name = args[:family_name]
      workgroup = args[:workgroup]
      fallback_role = args[:fallback_role] || "nurse"
    else
      raise "Expected 5-6 arguments, got #{args.to_a.size}"
    end

    team = Team.find_by(workgroup:)

    user =
      User.create!(email:, password:, family_name:, given_name:, fallback_role:)
    user.teams << team

    puts "User #{given_name} #{family_name} (#{email}) added to team " \
           "#{team.name} with role #{fallback_role}."
  end
end
