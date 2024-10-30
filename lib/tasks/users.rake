# frozen_string_literal: true

require_relative "../task_helpers"

namespace :users do
  desc "Create a new user and add them to a organisation."
  task :create,
       %i[email password given_name family_name organisation_ods_code] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter email:", required: true
      password = prompt_user_for "Enter password:", required: true
      given_name = prompt_user_for "Enter given name:", required: true
      family_name = prompt_user_for "Enter family name:", required: true
      organisation_ods_code =
        prompt_user_for "Enter organisation ODS code:", required: true
    elsif args.to_a.size == 5
      email = args[:email]
      password = args[:password]
      given_name = args[:given_name]
      family_name = args[:family_name]
      organisation_ods_code = args[:organisation_ods_code]
    elsif args.to_a.size != 5
      raise "Expected 5 arguments got #{args.to_a.size}"
    end

    organisation = Organisation.find_by!(ods_code: organisation_ods_code)

    user = User.create!(email:, password:, family_name:, given_name:)
    user.organisations << organisation

    puts "User #{given_name} #{family_name} (#{email}) added to organisation #{organisation.name}."
  end
end
