# frozen_string_literal: true

require_relative "../task_helpers"

namespace :clinics do
  desc "Create a new clinic location and add it to a team."
  task :create,
       %i[name address town county postcode ods_code team_ods_code] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      name = prompt_user_for "Enter location name:", required: true
      address_line_1 = prompt_user_for "Enter address:"
      address_town = prompt_user_for "Enter town:"
      address_county = prompt_user_for "Enter county:"
      address_postcode = prompt_user_for "Enter postcode:", required: true
      ods_code = prompt_user_for "Enter ODS code:"
      team_ods_code = prompt_user_for "Enter team ODS code:", required: true
    elsif args.to_a.size == 7
      name = args[:name]
      address_line_1 = args[:address]
      address_town = args[:town]
      address_county = args[:county]
      address_postcode = args[:postcode]
      ods_code = args[:urn]
      team_ods_code = args[:team_ods_code]
    elsif args.to_a.size != 7
      raise "Expected 7 arguments got #{args.to_a.size}"
    end

    team = Team.find_by!(ods_code: team_ods_code)

    location =
      Location.create!(
        type: :clinic,
        name:,
        address_line_1:,
        address_town:,
        address_county:,
        address_postcode:,
        ods_code:,
        team:
      )

    puts "Location #{name} (id: #{location.id}) added to team #{team.name}."
  end
end
