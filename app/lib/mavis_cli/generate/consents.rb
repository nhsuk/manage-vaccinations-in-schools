# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class Consents < Dry::CLI::Command
      desc "Generate consents"
      option :organisation,
             aliases: ["-o"],
             default: "A9A5A",
             desc: "ODS code of organisation to generate consents for"
      option :programme_type,
             aliases: ["-p"],
             default: "hpv",
             desc:
               "Programme type to generate consents for (hpv, menacwy, td_ipv, etc)"
      option :session_id,
             aliases: ["-s"],
             desc:
               "Generate consents for patients in a session, instead of across the entire organisation"
      option :given,
             default: 0,
             aliases: ["-g"],
             desc: "Number of given consents to create"
      option :needing_triage,
             default: 0,
             aliases: ["-N"],
             desc: "Number of given consents that need triage to create"
      option :refused,
             default: 0,
             aliases: ["-r"],
             desc: "Number of refused consents to create"

      def call(
        organisation:,
        programme_type:,
        given:,
        needing_triage:,
        refused:,
        session_id: nil,
        **
      )
        MavisCLI.load_rails

        session = Session.find(session_id) if session_id

        ::Generate::Consents.call(
          organisation: Organisation.find_by(ods_code: organisation),
          programme: Programme.find_by(type: programme_type),
          session:,
          given: given.to_i,
          given_needs_triage: needing_triage.to_i,
          refused: refused.to_i
        )
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "consents", Generate::Consents
  end
end
