# frozen_string_literal: true

module MavisCLI
  module Teams
    class CreateSessions < Dry::CLI::Command
      desc "Create sessions for all locations"

      argument :workgroup, required: true, desc: "The workgroup of the team"

      option :academic_year,
             type: :integer,
             desc: "The academic year to create the sessions for"

      def call(workgroup:, academic_year: nil)
        MavisCLI.load_rails

        team = Team.find_by(workgroup:)

        if team.nil?
          warn "Could not find team."
          return
        end

        academic_year ||= AcademicYear.pending

        TeamSessionsFactory.call(team, academic_year:)
      end
    end
  end

  register "teams" do |prefix|
    prefix.register "create-sessions", Teams::CreateSessions
  end
end
