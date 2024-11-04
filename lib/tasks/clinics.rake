# frozen_string_literal: true

require_relative "../task_helpers"

namespace :clinics do
  desc "Create a new clinic location and add it to a organisation."
  task :create,
       %i[name address town postcode ods_code organisation_ods_code] =>
         :environment do |_task, args|
    include TaskHelpers

    if args.to_a.empty? && $stdin.isatty && $stdout.isatty
      name = prompt_user_for "Enter location name:", required: true
      address_line_1 = prompt_user_for "Enter address:"
      address_town = prompt_user_for "Enter town:"
      address_postcode = prompt_user_for "Enter postcode:", required: true
      ods_code = prompt_user_for "Enter ODS code:"
      organisation_ods_code =
        prompt_user_for "Enter organisation ODS code:", required: true
    elsif args.to_a.size == 6
      name = args[:name]
      address_line_1 = args[:address]
      address_town = args[:town]
      address_postcode = args[:postcode]
      ods_code = args[:ods_code]
      organisation_ods_code = args[:organisation_ods_code]
    elsif args.to_a.size != 6
      raise "Expected 6 arguments got #{args.to_a.size}"
    end

    organisation = Organisation.find_by!(ods_code: organisation_ods_code)
    team = organisation.generic_team

    location =
      team.locations.create!(
        type: :community_clinic,
        name:,
        address_line_1:,
        address_town:,
        address_postcode:,
        ods_code:
      )

    puts "Location #{name} (id: #{location.id}) added to organisation #{organisation.name}."
  end
end
