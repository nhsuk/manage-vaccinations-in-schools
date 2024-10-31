# frozen_string_literal: true

require_relative "../task_helpers"

namespace :teams do
  desc <<-DESC
    Create a new team within an organisation.
  
    Usage:
      rake team:create # Complete the prompts
      rake team:create[ods_code,name,email,phone]
  DESC
  task :create, %i[ods_code name email phone] => :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      ods_code = prompt_user_for "Enter organisation ODS code:", required: true
      name = prompt_user_for "Enter team name:", required: true
      email = prompt_user_for "Enter team email:", required: true
      phone = prompt_user_for "Enter team phone:", required: true
    elsif args.to_a.size == 4
      ods_code = args[:ods_code]
      name = args[:name]
      email = args[:email]
      phone = args[:phone]
    elsif args.to_a.size != 4
      raise "Expected 4 arguments got #{args.to_a.size}"
    end

    ActiveRecord::Base.transaction do
      organisation = Organisation.find_by!(ods_code:)

      organisation.teams.create!(name:, email:, phone:)

      puts "New #{team.name} team with ID #{team.id} created."
    end
  end
end
