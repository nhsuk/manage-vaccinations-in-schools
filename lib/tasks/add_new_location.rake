# frozen_string_literal: true

require_relative "../task_helpers"

desc <<-DESC
  Add a new location

  Usage:
    rake add_new_location # Complete the prompts
    rake add_new_location[name,address,town,postcode,county,urn,team_id]
DESC
task :add_new_location,
     %i[name address town county postcode urn team_id] =>
       :environment do |_task, args|
  include TaskHelpers

  if args.to_a.empty? && $stdin.isatty && $stdout.isatty
    name = prompt_user_for "Enter location name:", required: true
    address = prompt_user_for "Enter address:"
    town = prompt_user_for "Enter town:"
    county = prompt_user_for "Enter county:"
    postcode = prompt_user_for "Enter postcode:", required: true
    urn = prompt_user_for "Enter URN:"
    team_id = prompt_user_for "Enter team ID:", required: true
  elsif args.to_a.size == 7
    name = args[:name]
    address = args[:address]
    town = args[:town]
    county = args[:county]
    postcode = args[:postcode]
    urn = args[:urn]
    team_id = args[:team_id]
  elsif args.to_a.size != 7
    raise "Expected 7 arguments got #{args.to_a.size}"
  end

  location =
    Location.create!(name:, address:, town:, county:, urn:, postcode:, team_id:)

  puts "Location #{name} (id: #{location.id}) added to team #{Team.find(team_id).name}."
end
