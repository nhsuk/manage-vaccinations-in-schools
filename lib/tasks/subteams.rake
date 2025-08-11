# frozen_string_literal: true

require_relative "../task_helpers"

namespace :subteams do
  desc <<-DESC
    Create a new subteam within a team.

    Usage:
      rake subteams:create # Complete the prompts
      rake subteams:create[workgroup,name,email,phone]
  DESC
  task :create, %i[workgroup name email phone] => :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      workgroup = prompt_user_for "Enter team workgroup:", required: true
      name = prompt_user_for "Enter subteam name:", required: true
      email = prompt_user_for "Enter subteam email:", required: true
      phone = prompt_user_for "Enter subteam phone:", required: true
    elsif args.to_a.size == 4
      workgroup = args[:workgroup]
      name = args[:name]
      email = args[:email]
      phone = args[:phone]
    elsif args.to_a.size != 4
      raise "Expected 4 arguments got #{args.to_a.size}"
    end

    ActiveRecord::Base.transaction do
      team = Team.find_by!(workgroup:)

      subteam = team.subteams.create!(name:, email:, phone:)

      puts "New #{subteam.name} subteam with ID #{subteam.id} created."
    end
  end
end
