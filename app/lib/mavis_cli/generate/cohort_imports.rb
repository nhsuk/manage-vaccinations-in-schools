# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class CohortImports < Dry::CLI::Command
      desc "Generate cohort imports"

      option :team_workgroup,
             aliases: ["-w"],
             default: "A9A5A",
             desc: "Workgroup of team to generate consents for"

      option :programme_type,
             aliases: ["-p"],
             default: "hpv",
             desc:
               "Programme type to generate consents for (hpv, menacwy, td_ipv, etc)"

      option :patient_count,
             aliases: ["-c"],
             type: :integer,
             required: true,
             default: 10,
             desc: "Number of patients to create"

      def call(team_workgroup:, programme_type:, patient_count:)
        MavisCLI.load_rails

        patient_count = patient_count.to_i
        progress_bar = MavisCLI.progress_bar(patient_count)

        puts "Generating cohort import for team #{team_workgroup} with" \
               " #{patient_count} patients..."

        result =
          ::Generate::CohortImports.call(
            team: Team.find_by(workgroup: team_workgroup),
            programme: Programme.find_by(type: programme_type),
            patient_count:,
            progress_bar:
          )

        puts "\nCohort import CSV generated: #{result}"
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "cohort-imports", Generate::CohortImports
  end
end
