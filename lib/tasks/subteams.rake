# frozen_string_literal: true

require_relative "../task_helpers"

namespace :subteams do
  desc <<-DESC
    Create a new subteam within a team.

    Usage:
      rake subteams:create # Complete the prompts
      rake subteams:create[ods_code,name,email,phone]
  DESC
  task :create, %i[ods_code name email phone] => :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      ods_code = prompt_user_for "Enter team ODS code:", required: true
      name = prompt_user_for "Enter subteam name:", required: true
      email = prompt_user_for "Enter subteam email:", required: true
      phone = prompt_user_for "Enter subteam phone:", required: true
    elsif args.to_a.size == 4
      ods_code = args[:ods_code]
      name = args[:name]
      email = args[:email]
      phone = args[:phone]
    elsif args.to_a.size != 4
      raise "Expected 4 arguments got #{args.to_a.size}"
    end

    ActiveRecord::Base.transaction do
      team = Team.find_by!(ods_code:)

      subteam = team.subteams.create!(name:, email:, phone:)

      puts "New #{subteam.name} subteam with ID #{subteam.id} created."
    end
  end
end
