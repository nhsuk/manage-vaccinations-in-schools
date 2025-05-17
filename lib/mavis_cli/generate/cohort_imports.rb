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

        ::Generate::CohortImports.call(patient_count: patients.to_i)
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "cohort-imports", Generate::CohortImports
  end
end
