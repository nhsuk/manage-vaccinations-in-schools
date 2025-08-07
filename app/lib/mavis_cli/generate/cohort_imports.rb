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
      option :ods_code,
             type: :string,
             default: "A9A5A",
             desc: "ODS code of the organisation to use for the cohort import"

      def call(patients:, ods_code:)
        MavisCLI.load_rails

        patient_count = patients.to_i
        progress_bar = MavisCLI.progress_bar(patient_count)

        puts "Generating cohort import for ods code #{ods_code} with" \
               " #{patient_count} patients..."

        result =
          ::Generate::CohortImports.call(
            ods_code:,
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
