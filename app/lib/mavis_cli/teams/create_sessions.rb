# frozen_string_literal: true

module MavisCLI
  module Teams
    class CreateSessions < Dry::CLI::Command
      desc "Create sessions for all locations"

      argument :ods_code,
               required: true,
               desc: "The ODS code of the organisation"

      option :academic_year,
             type: :integer,
             desc: "The academic year to create the sessions for"

      def call(ods_code:, academic_year: nil)
        MavisCLI.load_rails

        team = Team.find_by(ods_code:)

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
