# frozen_string_literal: true

module MavisCLI
  module Users
    class Create < Dry::CLI::Command
      desc "Creates a new user"

      argument :workgroup, required: true, desc: "Workgroup of the team"

      option :email, required: true, desc: "Email address of the user"
      option :password, required: true, desc: "Password of the user"
      option :given_name, required: true, desc: "Given name of the user"
      option :family_name, required: true, desc: "Family name of the user"
      option :fallback_role, default: "nurse", desc: "Non-CIS2 role of the user"

      def call(
        workgroup:,
        email:,
        password:,
        given_name:,
        family_name:,
        fallback_role:
      )
        MavisCLI.load_rails

        team = Team.find_by(workgroup:)

        if team.nil?
          warn "Could not find team."
          return
        end

        user =
          team.users.create!(
            email:,
            password:,
            given_name:,
            family_name:,
            fallback_role:
          )

        puts "New #{user.email} user with ID #{user.id} created."
      end
    end
  end

  register "users" do |prefix|
    prefix.register "create", Users::Create
  end
end
