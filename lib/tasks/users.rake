# frozen_string_literal: true

require_relative "../task_helpers"

namespace :users do
  desc "Create a new user and add them to a organisation."
  task :create,
       %i[
         email
         password
         given_name
         family_name
         organisation_ods_code
         fallback_role
       ] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      email = prompt_user_for "Enter email:", required: true
      password = prompt_user_for "Enter password:", required: true
      given_name = prompt_user_for "Enter given name:", required: true
      family_name = prompt_user_for "Enter family name:", required: true
      organisation_ods_code =
        prompt_user_for "Enter organisation ODS code:", required: true
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
      organisation_ods_code = args[:organisation_ods_code]
      fallback_role = args[:fallback_role] || "nurse"
    else
      raise "Expected 5-6 arguments, got #{args.to_a.size}"
    end

    organisation = Organisation.find_by!(ods_code: organisation_ods_code)

    user =
      User.create!(email:, password:, family_name:, given_name:, fallback_role:)
    user.organisations << organisation

    puts "User #{given_name} #{family_name} (#{email}) added to organisation " \
           "#{organisation.name} with role #{fallback_role}."
  end
end
