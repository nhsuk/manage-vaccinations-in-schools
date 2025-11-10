# frozen_string_literal: true

module MavisCLI
  module Generate
    class VaccinationRecords < Dry::CLI::Command
      desc "Generate vaccination records (and attendances if required)"
      option :team_workgroup,
             aliases: ["-w"],
             default: "A9A5A",
             desc: "Workgroup of team to generate consents for"
      option :programme_type,
             aliases: ["-p"],
             default: "hpv",
             desc:
               "Programme type to generate consents for (hpv, menacwy, td_ipv, etc)"
      option :session_id,
             aliases: ["-s"],
             desc:
               "Generate consents for patients in a session, instead of" \
                 " across the entire team"
      option :administered,
             default: 0,
             aliases: ["-A"],
             desc: "Number of administered vaccination records to create"

      def call(
        team_workgroup:,
        programme_type:,
        administered:,
        session_id: nil,
        **
      )
        MavisCLI.load_rails

        session = Session.find(session_id) if session_id

        ::Generate::VaccinationRecords.call(
          team: Team.find_by(workgroup: team_workgroup),
          programme: Programme.find_by(type: programme_type),
          session:,
          administered: administered.to_i
        )
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "vaccination-records", Generate::VaccinationRecords
  end
end
