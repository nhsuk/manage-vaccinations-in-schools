# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class CohortImports < Dry::CLI::Command
      desc "Generate cohort imports"
      option :patients,
             type: :integer,
             required: true,
             default: 10,
             desc: "Number of patients to create"

      def call(patients:)
        MavisCLI.load_rails

        patient_count = patients.to_i
        puts "Generating cohort import with #{patient_count} patients..."
        progress_bar = MavisCLI.progress_bar(patient_count)

        result =
          ::Generate::CohortImports.call(
            patient_count: patient_count,
            progress_bar: progress_bar
          )

        puts "\nCohort import CSV generated: #{result}"
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "cohort-imports", Generate::CohortImports
  end
end
