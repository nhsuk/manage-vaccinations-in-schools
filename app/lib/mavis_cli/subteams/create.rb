# frozen_string_literal: true

module MavisCLI
  module Subteams
    class Create < Dry::CLI::Command
      desc "Creates a new subteam"

      argument :workgroup, required: true, desc: "Workgroup of the team"

      option :name, required: true, desc: "Name of the subteam"
      option :email, required: true, desc: "Email address of the subteam"
      option :phone, required: true, desc: "Phone number of the subteam"

      def call(workgroup:, name:, email:, phone:)
        MavisCLI.load_rails

        team = Team.find_by(workgroup:)

        if team.nil?
          warn "Could not find team."
          return
        end

        subteam = team.subteams.create!(name:, email:, phone:)

        puts "New #{subteam.name} subteam with ID #{subteam.id} created."
      end
    end
  end

  register "subteams" do |prefix|
    prefix.register "create", Subteams::Create
  end
end
